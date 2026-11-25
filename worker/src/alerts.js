// Reports an AI failure to the alerts Worker (github.com/ddombrov/alerts), which emails it at most once a day per model.
const ALERTS_URL = "https://alerts.danieldombrovsky9.workers.dev/report";
const RETIRED = /model_not_found|not found|does not exist|no longer|deprecated|retired|decommissioned/i;

export async function reportAiFailure(token, project, model, next, detail) {
  if (!token) return;
  const kind = RETIRED.test(detail) && !/quota|billing|rate limit/i.test(detail) ? "model-retired" : "ai-error";
  try {
    await fetch(ALERTS_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
      body: JSON.stringify({ project, kind, model, next, detail: String(detail).slice(0, 1500) }),
    });
  } catch (error) {
    console.error("Could not reach the alerts Worker", error);
  }
}
