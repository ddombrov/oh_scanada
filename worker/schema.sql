-- The community board: posts, their comments, and likes. A browser is identified by a random device id
-- it keeps to itself; the API never returns it, only whether a post or comment is yours.
CREATE TABLE IF NOT EXISTS posts (
  id TEXT PRIMARY KEY,
  device TEXT NOT NULL,
  name TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  shares INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS comments (
  id TEXT PRIMARY KEY,
  post_id TEXT NOT NULL,
  device TEXT NOT NULL,
  name TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS comments_by_post ON comments (post_id, created_at);

-- kind is 'post' or 'comment'.
CREATE TABLE IF NOT EXISTS likes (
  kind TEXT NOT NULL,
  target TEXT NOT NULL,
  device TEXT NOT NULL,
  PRIMARY KEY (kind, target, device)
);

INSERT OR IGNORE INTO posts (id, device, name, title, content, shares, created_at) VALUES
  ('welcome', 'oh-scanada', 'Oh Scanada', 'Welcome to the community',
   'Share Canadian products you have found, ask where to buy something made here, or tell people what you think of a brand.',
   0, 1795305600000);
