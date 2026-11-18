// Serves the app and answers its AI requests. The OpenAI key is a Worker secret and never reaches the browser.

const MODEL = "gpt-4o-mini";

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
        temperature: 0.7,
        max_tokens: 150,
      };
    case "sustainability":
      return {
        system: "You are a sustainability rating system.",
        user: `Rate the sustainability of ${name} with ingredients: ${ingredients} on a scale of 1.0 to 5.0. Return ONLY a number.`,
        temperature: 0.3,
        max_tokens: 10,
      };
    case "phone":
      return {
        system: "You answer with a company's customer service phone number only.",
        user: `What is the phone number for ${clip(body.brand, 100)}?`,
        temperature: 0,
        max_tokens: 100,
      };
    default:
      return null;
  }
}

const json = (data, status = 200) =>
  new Response(JSON.stringify(data), { status, headers: { "Content-Type": "application/json" } });

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname !== "/api/ai") return env.ASSETS.fetch(request);
    if (request.method !== "POST") return json({ error: "Use POST." }, 405);

    const { success } = await env.AI_LIMIT.limit({ key: request.headers.get("CF-Connecting-IP") ?? "unknown" });
    if (!success) return json({ error: "Too many requests. Try again in a minute." }, 429);

    const body = await request.json().catch(() => null);
    const prompt = body && buildRequest(body);
    if (!prompt) return json({ error: "Unknown request." }, 400);

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${env.OPENAI_API_KEY}` },
      body: JSON.stringify({
        model: MODEL,
        messages: [
          { role: "system", content: prompt.system },
          { role: "user", content: prompt.user },
        ],
        temperature: prompt.temperature,
        max_tokens: prompt.max_tokens,
      }),
    });
    if (!response.ok) {
      console.error("OpenAI error", response.status, await response.text());
      return json({ error: "The AI service is unavailable." }, 502);
    }
    return json(await response.json());
  },
};
