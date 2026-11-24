const CACHE_NAME = "common-need-pwa-v3";
const OFFLINE_ASSETS = [
  "./",
  "./index.html",
  "./manifest.json"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(OFFLINE_ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      const staleKeys = keys.filter((k) => k !== CACHE_NAME);
      await Promise.all(staleKeys.map((k) => caches.delete(k)));
      await self.clients.claim();

      if (staleKeys.length > 0) {
        const windowClients = await self.clients.matchAll({ type: "window" });
        for (const client of windowClients) {
          if ("navigate" in client) {
            try {
              await client.navigate(client.url);
            } catch (_err) {}
          }
        }
      }
    })()
  );
});

self.addEventListener("fetch", (event) => {
  const req = event.request;
  if (req.method !== "GET") return;

  const isHtmlNavigation =
    req.mode === "navigate" ||
    req.destination === "document" ||
    req.url.endsWith("/") ||
    req.url.endsWith(".html");

  if (isHtmlNavigation) {
    event.respondWith(
      fetch(req, { cache: "no-store" })
        .then(async (networkRes) => {
          if (networkRes && networkRes.ok) {
            const cache = await caches.open(CACHE_NAME);
            cache.put(req, networkRes.clone());
          }
          return networkRes;
        })
        .catch(() => caches.match(req))
    );
    return;
  }

  event.respondWith(
    caches.match(req).then((cached) => cached || fetch(req))
  );
});
