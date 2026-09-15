/**
 * Resilient FastAPI Client with Render Hibernation Cold-Start Handling
 * Automatically pings and waits for Render free-tier backend to wake up (up to 45s)
 * before dispatching RAG and Vision requests.
 */

function getFastApiBaseUrl(): string {
  return (
    process.env.FASTAPI_BACKEND_URL ||
    process.env.NEXT_PUBLIC_FASTAPI_BACKEND_URL ||
    "https://magicmirror-g7rh.onrender.com"
  );
}

/**
 * Pings the FastAPI health check endpoint and waits if Render is waking up from hibernation.
 */
export async function ensureBackendAwake(maxWaitMs: number = 40000): Promise<boolean> {
  const baseUrl = getFastApiBaseUrl();
  const startTime = Date.now();
  let attempt = 0;

  console.log(`[FastAPI Client] Vérification du statut du backend (${baseUrl})...`);

  while (Date.now() - startTime < maxWaitMs) {
    attempt++;
    try {
      const controller = new AbortController();
      const id = setTimeout(() => controller.abort(), 6000);

      const res = await fetch(`${baseUrl}/api/v1/health`, {
        method: "GET",
        signal: controller.signal,
        headers: { "Cache-Control": "no-cache" },
      });
      clearTimeout(id);

      if (res.ok) {
        const data = await res.json();
        if (data.status === "online") {
          console.log(`[FastAPI Client] ✅ Backend en ligne et prêt (Tentative ${attempt}) !`);
          return true;
        }
      }
    } catch (err: any) {
      console.log(`[FastAPI Client] ⏳ Réveil du backend en cours (Tentative ${attempt})... Attente 3s`);
    }

    // Wait 3s between retries
    await new Promise((resolve) => setTimeout(resolve, 3000));
  }

  console.warn(`[FastAPI Client] ⚠️ Délai de réveil dépassé (${maxWaitMs}ms)`);
  return false;
}

/**
 * Dispatches a recommendation request to Python FastAPI on Render.
 */
export async function fetchFastApiRecommendations(payload: any, timeoutMs: number = 45000): Promise<any> {
  const baseUrl = getFastApiBaseUrl();

  // 1. Ensure backend is awake first
  await ensureBackendAwake(30000);

  // 2. Dispatch request with generous timeout for LLM inference
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const res = await fetch(`${baseUrl}/api/v1/recommendations`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });
    clearTimeout(id);

    if (res.ok) {
      return await res.json();
    } else {
      const text = await res.text();
      throw new Error(`FastAPI a retourné le code ${res.status}: ${text}`);
    }
  } catch (err) {
    clearTimeout(id);
    throw err;
  }
}

/**
 * Dispatches a camera frame analysis request to Python FastAPI on Render.
 */
export async function fetchFastApiVisionAnalyze(payload: any, timeoutMs: number = 45000): Promise<any> {
  const baseUrl = getFastApiBaseUrl();

  await ensureBackendAwake(30000);

  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const res = await fetch(`${baseUrl}/api/v1/vision/analyze`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });
    clearTimeout(id);

    if (res.ok) {
      return await res.json();
    } else {
      const text = await res.text();
      throw new Error(`FastAPI Vision a retourné le code ${res.status}: ${text}`);
    }
  } catch (err) {
    clearTimeout(id);
    throw err;
  }
}
