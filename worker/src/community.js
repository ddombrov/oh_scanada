// The community board's API, stored in D1. Posts and comments carry the name the poster chose; the device id
// that owns them is a random secret kept by the browser and never sent back out.

const DEVICE = /^[a-f0-9]{32}$/;
const DAY_SECONDS = 24 * 60 * 60;
// Site-wide writes a day (posts, comments, likes, shares), so the board can't be flooded.
const DAILY_WRITES = 2000;

const json = (data, status = 200) =>
  new Response(JSON.stringify(data), { status, headers: { "Content-Type": "application/json" } });
const text = (value, max) => String(value ?? "").trim().slice(0, max);
const newId = () => crypto.randomUUID().replace(/-/g, "").slice(0, 20);

async function postRows(db, device, where = "", args = []) {
  const { results } = await db
    .prepare(
      `SELECT p.id, p.name, p.title, p.content, p.shares, p.created_at,
              (SELECT COUNT(*) FROM likes l WHERE l.kind = 'post' AND l.target = p.id) AS likes,
              (SELECT COUNT(*) FROM comments c WHERE c.post_id = p.id) AS comments,
              EXISTS (SELECT 1 FROM likes l WHERE l.kind = 'post' AND l.target = p.id AND l.device = ?1) AS is_liked,
              p.device = ?1 AS mine
       FROM posts p ${where} ORDER BY p.created_at DESC LIMIT 200`,
    )
    .bind(device, ...args)
    .all();
  return results.map((r) => ({ ...r, is_liked: !!r.is_liked, mine: !!r.mine }));
}

async function toggleLike(db, kind, target, device) {
  const deleted = await db.prepare("DELETE FROM likes WHERE kind = ? AND target = ? AND device = ?").bind(kind, target, device).run();
  const liked = deleted.meta.changes === 0;
  if (liked) await db.prepare("INSERT INTO likes (kind, target, device) VALUES (?, ?, ?)").bind(kind, target, device).run();
  const { n } = await db.prepare("SELECT COUNT(*) AS n FROM likes WHERE kind = ? AND target = ?").bind(kind, target).first();
  return { liked, likes: n };
}

// Returns a Response for /api/posts and /api/comments requests, or null for any other path.
export async function community(request, env, url) {
  const parts = url.pathname.split("/").filter(Boolean); // ["api", "posts", id?, action?]
  if (parts[0] !== "api" || !["posts", "comments"].includes(parts[1])) return null;
  const db = env.COMMUNITY;

  if (request.method === "GET") {
    const device = DEVICE.test(url.searchParams.get("device") ?? "") ? url.searchParams.get("device") : "";
    if (parts[1] === "posts" && parts.length === 2) {
      const posts = await postRows(db, device, url.searchParams.get("mine") === "1" ? "WHERE p.device = ?2" : "", url.searchParams.get("mine") === "1" ? [device] : []);
      return json(posts);
    }
    if (parts[1] === "posts" && parts[3] === "comments") {
      const { results } = await db
        .prepare(
          `SELECT c.id, c.name, c.content, c.created_at,
                  (SELECT COUNT(*) FROM likes l WHERE l.kind = 'comment' AND l.target = c.id) AS likes,
                  EXISTS (SELECT 1 FROM likes l WHERE l.kind = 'comment' AND l.target = c.id AND l.device = ?2) AS is_liked,
                  c.device = ?2 AS mine
           FROM comments c WHERE c.post_id = ?1 ORDER BY c.created_at DESC LIMIT 500`,
        )
        .bind(parts[2], device)
        .all();
      return json(results.map((r) => ({ ...r, is_liked: !!r.is_liked, mine: !!r.mine })));
    }
    return json({ error: "Not found." }, 404);
  }

  if (request.method !== "POST") return json({ error: "Use GET or POST." }, 405);
  const body = await request.json().catch(() => ({}));
  if (!DEVICE.test(body.device ?? "")) return json({ error: "Missing device." }, 400);

  const { success } = await env.COMMUNITY_LIMIT.limit({ key: request.headers.get("CF-Connecting-IP") ?? "unknown" });
  if (!success) return json({ error: "Too many changes in a row. Try again in a minute." }, 429);
  const dayKey = `community:${new Date().toISOString().slice(0, 10)}`;
  const writes = Number(await env.SCANNER_USAGE.get(dayKey)) || 0;
  if (writes >= DAILY_WRITES) return json({ error: "The community board has reached today's limit. Try again tomorrow." }, 429);
  await env.SCANNER_USAGE.put(dayKey, String(writes + 1), { expirationTtl: 2 * DAY_SECONDS });

  const name = text(body.name, 40) || "Guest";
  const [, kind, id, action] = parts;

  if (kind === "posts" && !id) {
    const title = text(body.title, 120), content = text(body.content, 2000);
    if (!title || !content) return json({ error: "A post needs a title and some text." }, 400);
    const postId = newId();
    await db.prepare("INSERT INTO posts (id, device, name, title, content, created_at) VALUES (?, ?, ?, ?, ?, ?)")
      .bind(postId, body.device, name, title, content, Date.now()).run();
    return json({ id: postId });
  }
  if (kind === "posts" && action === "like") return json(await toggleLike(db, "post", id, body.device));
  if (kind === "posts" && action === "share") {
    await db.prepare("UPDATE posts SET shares = shares + 1 WHERE id = ?").bind(id).run();
    return json({ ok: true });
  }
  if (kind === "posts" && action === "comments") {
    const content = text(body.content, 1000);
    if (!content) return json({ error: "A comment needs some text." }, 400);
    const exists = await db.prepare("SELECT 1 FROM posts WHERE id = ?").bind(id).first();
    if (!exists) return json({ error: "That post no longer exists." }, 404);
    const commentId = newId();
    await db.prepare("INSERT INTO comments (id, post_id, device, name, content, created_at) VALUES (?, ?, ?, ?, ?, ?)")
      .bind(commentId, id, body.device, name, content, Date.now()).run();
    return json({ id: commentId });
  }
  if (kind === "posts" && action === "delete") {
    const result = await db.prepare("DELETE FROM posts WHERE id = ? AND device = ?").bind(id, body.device).run();
    if (result.meta.changes) {
      await db.batch([
        db.prepare("DELETE FROM likes WHERE kind = 'comment' AND target IN (SELECT id FROM comments WHERE post_id = ?)").bind(id),
        db.prepare("DELETE FROM comments WHERE post_id = ?").bind(id),
        db.prepare("DELETE FROM likes WHERE kind = 'post' AND target = ?").bind(id),
      ]);
    }
    return json({ deleted: !!result.meta.changes });
  }
  if (kind === "comments" && action === "like") return json(await toggleLike(db, "comment", id, body.device));
  if (kind === "comments" && action === "delete") {
    const result = await db.prepare("DELETE FROM comments WHERE id = ? AND device = ?").bind(id, body.device).run();
    if (result.meta.changes) await db.prepare("DELETE FROM likes WHERE kind = 'comment' AND target = ?").bind(id).run();
    return json({ deleted: !!result.meta.changes });
  }
  return json({ error: "Not found." }, 404);
}
