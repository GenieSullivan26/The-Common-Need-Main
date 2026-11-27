const CACHE_NAME = "common-need-pwa-v5";
const OFFLINE_ASSETS = [
  "./",
  "./index.html",
  "./manifest.json"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE_NAME);
      await Promise.all(
        OFFLINE_ASSETS.map(async (assetUrl) => {
          try {
            const freshRes = await fetch(assetUrl, { cache: "no-store" });
            if (freshRes && freshRes.ok) {
              await cache.put(assetUrl, freshRes.clone());
            }
          } catch (_err) {}
        })
      );
      await self.skipWaiting();
    })()
  );
});

self.addEventListener("message", (event) => {
  if (!event.data) return;
  if (event.data.type === "SKIP_WAITING") {
    self.skipWaiting();
  } else if (event.data.type === "PURGE_STALE_CACHES") {
    event.waitUntil(
      caches.keys().then((keys) =>
        Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
      )
    );
  }
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

  let pathname = "";
  try {
    pathname = new URL(req.url).pathname;
  } catch (_err) {}

  const lastSegment = pathname.split("/").pop() || "";
  const acceptHeader = req.headers.get("accept") || "";
  const isHtmlNavigation =
    req.mode === "navigate" ||
    req.destination === "document" ||
    acceptHeader.includes("text/html") ||
    pathname.endsWith("/") ||
    pathname.endsWith(".html") ||
    !lastSegment.includes(".");

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
        .catch(async () => {
          return (
            (await caches.match(req)) ||
            (await caches.match(req, { ignoreSearch: true })) ||
            (await caches.match("./index.html"))
          );
        })
    );
    return;
  }

  event.respondWith(
    fetch(req, { cache: "no-cache" })
      .then(async (res) => {
        if (res && res.ok) {
          const cache = await caches.open(CACHE_NAME);
          cache.put(req, res.clone());
        }
        return res;
      })
      .catch(() => caches.match(req, { ignoreSearch: true }))
  );
});
