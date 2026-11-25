// Serves the app, answers its AI requests and runs the community board. The OpenAI key is a Worker secret and never reaches the browser.
import { community } from "./community.js";
import { reportAiFailure } from "./alerts.js";

// The models to try, cheapest first. A model that fails (retired, or an outage) is skipped for the next one, and the
// failure is emailed through the alerts Worker. These models only accept the default temperature.
// Each passed the three requests below on a real product before being listed.
const MODELS = ["gpt-6-luna", "gpt-5.6-luna"];
// Every product page makes two AI requests (analysis and rating), so this allows about 150 product views a day.
const DAILY_LIMIT = 300;
const DAY_SECONDS = 24 * 60 * 60;

const clip = (value, max) => String(value ?? "").slice(0, max);

// Only these three requests are accepted, and the prompts are built here, so the endpoint can't be used for anything else.
function buildRequest(body) {
  const name = clip(body.name, 200) || "Unknown Product";
  const ingredients = clip(body.ingredients, 2000);
  switch (body.task) {
    case "analysis":
      return {
        system: "You are a helpful product analysis assistant.",
        user: `Analyze this product: ${name}
UPC: ${clip(body.upc, 20)}
Ingredients: ${ingredients}
Brand: ${clip(body.brands, 200)}
Categories: ${clip(body.categories, 500)}

Provide a brief analysis of this product focusing on:
1. Health benefits or concerns
2. Sustainability aspects
3. Key quality indicators
Keep it concise and consumer-friendly, 2-3 sentences.`,
        max_tokens: 150,
      };
    case "sustainability":
      return {
        system: "You are a sustainability rating system.",
        user: `Rate the sustainability of ${name} with ingredients: ${ingredients} on a scale of 1.0 to 5.0. Return ONLY a number.`,
        max_tokens: 10,
      };
    case "phone":
      return {
        system: "You answer with a company's customer service phone number only.",
        user: `What is the phone number for ${clip(body.brand, 100)}?`,
        max_tokens: 100,
      };
    default:
      return null;
  }
}

const json = (data, status = 200) =>
  new Response(JSON.stringify(data), { status, headers: { "Content-Type": "application/json" } });

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const board = await community(request, env, url);
    if (board) return board;
    if (url.pathname !== "/api/ai") return env.ASSETS.fetch(request);
    if (request.method !== "POST") return json({ error: "Use POST." }, 405);

    const { success } = await env.AI_LIMIT.limit({ key: request.headers.get("CF-Connecting-IP") ?? "unknown" });
    if (!success) return json({ error: "Too many requests. Try again in a minute." }, 429);

    const body = await request.json().catch(() => null);
    const prompt = body && buildRequest(body);
    if (!prompt) return json({ error: "Unknown request." }, 400);

    // KV counts are eventually consistent, so the cap can overshoot slightly under heavy load; that is fine here.
    const dayKey = `day:${new Date().toISOString().slice(0, 10)}`;
    const usedToday = Number(await env.SCANNER_USAGE.get(dayKey)) || 0;
    if (usedToday >= DAILY_LIMIT) return json({ error: "The AI summary has reached today's limit. Try again tomorrow." }, 429);
    await env.SCANNER_USAGE.put(dayKey, String(usedToday + 1), { expirationTtl: 2 * DAY_SECONDS });

    for (let i = 0; i < MODELS.length; i++) {
      const response = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${env.OPENAI_API_KEY}` },
        body: JSON.stringify({
          model: MODELS[i],
          messages: [
            { role: "system", content: prompt.system },
            { role: "user", content: prompt.user },
          ],
          // These models think before answering, which would use up the small token limits; these short answers don't need it.
          reasoning_effort: "none",
          max_completion_tokens: prompt.max_tokens,
        }),
      });
      if (response.ok) return json(await response.json());
      const detail = await response.text();
      console.error("OpenAI error", MODELS[i], response.status, detail);
      ctx.waitUntil(reportAiFailure(env.ALERTS_TOKEN, "Oh Scanada scanner", MODELS[i], MODELS[i + 1] ?? "", `${response.status} ${detail}`));
    }
    return json({ error: "The AI service is unavailable." }, 502);
  },
};
