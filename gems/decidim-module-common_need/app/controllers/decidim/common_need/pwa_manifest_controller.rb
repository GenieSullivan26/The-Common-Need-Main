# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Serves the Web App Manifest (`/manifest.json`) and Offline Workbox/IndexedDB
    # Service Worker (`/service-worker.js`) for the 5-Role PWA Suite.
    class PwaManifestController < ActionController::Base
      skip_before_action :verify_authenticity_token, only: [:service_worker, :manifest], raise: false

      def manifest
        render json: {
          name: "The Common Need • Federated Mutual Aid Network",
          short_name: "Common Need",
          description: "5-Role Federated Mutual Aid & Zero-Means-Testing Community Resource Network (#OAK-01)",
          start_url: "/",
          scope: "/",
          display: "standalone",
          orientation: "portrait",
          theme_color: "#120924",
          background_color: "#120924",
          categories: Decidim::CommonNeed::COMMUNITY_TAXONOMY_CATEGORIES,
          icons: [
            {
              src: "/icons/common-need-192.png",
              sizes: "192x192",
              type: "image/png",
              purpose: "any maskable"
            },
            {
              src: "/icons/common-need-512.png",
              sizes: "512x512",
              type: "image/png",
              purpose: "any maskable"
            }
          ]
        }
      end

      def service_worker
        response.headers["Content-Type"] = "application/javascript; charset=utf-8"
        response.headers["Service-Worker-Allowed"] = "/"
        render plain: service_worker_js_payload
      end

      private

      def service_worker_js_payload
        <<~JS
          // ============================================================================
          // The Common Need • Offline-First Workbox/IndexedDB Service Worker
          // Caches PWA Shell, OSRM Route Polylines/Maneuvers, and Leaflet Map Tiles
          // ============================================================================
          const CACHE_VERSION = "common-need-pwa-v5";
          const SHELL_CACHE = `${CACHE_VERSION}-shell`;
          const TILE_CACHE = `${CACHE_VERSION}-leaflet-tiles`;
          const OSRM_CACHE = `${CACHE_VERSION}-osrm-routes`;
          const IDB_NAME = "common_need_offline_store";

          const PRECACHE_URLS = [
            "/",
            "/manifest.json"
          ];

          self.addEventListener("install", (event) => {
            event.waitUntil(
              caches.open(SHELL_CACHE).then(async (cache) => {
                await Promise.all(
                  PRECACHE_URLS.map(async (url) => {
                    try {
                      const res = await fetch(url, { cache: "no-store" });
                      if (res && res.ok) await cache.put(url, res);
                    } catch (_err) {}
                  })
                );
              }).then(() => self.skipWaiting())
            );
          });

          self.addEventListener("activate", (event) => {
            event.waitUntil(
              caches.keys().then((keys) =>
                Promise.all(
                  keys
                    .filter((key) => !key.startsWith(CACHE_VERSION))
                    .map((key) => caches.delete(key))
                )
              ).then(() => self.clients.claim())
            );
          });

          self.addEventListener("message", (event) => {
            if (!event.data) return;
            if (event.data.type === "SKIP_WAITING") {
              self.skipWaiting();
            } else if (event.data.type === "PURGE_STALE_CACHES") {
              event.waitUntil(
                caches.keys().then((keys) =>
                  Promise.all(
                    keys
                      .filter((key) => !key.startsWith(CACHE_VERSION))
                      .map((key) => caches.delete(key))
                  )
                )
              );
            }
          });

          self.addEventListener("fetch", (event) => {
            const { request } = event;
            if (request.method !== "GET") return;

            const url = new URL(request.url);

            // Cache-First strategy for Leaflet OpenStreetMap tiles
            if (url.hostname.includes("tile.openstreetmap.org")) {
              event.respondWith(
                caches.open(TILE_CACHE).then(async (cache) => {
                  const cached = await cache.match(request);
                  if (cached) return cached;
                  try {
                    const response = await fetch(request);
                    if (response.ok) cache.put(request, response.clone());
                    return response;
                  } catch (_err) {
                    return new Response("", { status: 204 });
                  }
                })
              );
              return;
            }

            // Network-First with Cache Fallback for OSRM route bundles & polylines
            if (url.pathname.includes("/offline_bundle") || url.pathname.includes("/route/v1/")) {
              event.respondWith(
                caches.open(OSRM_CACHE).then(async (cache) => {
                  try {
                    const response = await fetch(request);
                    if (response.ok) cache.put(request, response.clone());
                    return response;
                  } catch (_err) {
                    const cached = await cache.match(request);
                    return cached || new Response(JSON.stringify({ offline: true }), {
                      headers: { "Content-Type": "application/json" }
                    });
                  }
                })
              );
              return;
            }

            // Network-First for HTML navigation (prevents stale cached /member/ or /partner/ shells)
            const acceptHeader = request.headers.get("accept") || "";
            const isHtmlDoc =
              request.mode === "navigate" ||
              request.destination === "document" ||
              acceptHeader.includes("text/html") ||
              url.pathname.endsWith("/") ||
              url.pathname.endsWith(".html");

            if (isHtmlDoc) {
              event.respondWith(
                fetch(request, { cache: "no-cache" })
                  .then(async (response) => {
                    if (response && response.status === 200) {
                      const cache = await caches.open(SHELL_CACHE);
                      cache.put(request, response.clone());
                    }
                    return response;
                  })
                  .catch(() => caches.match(request))
              );
              return;
            }

            // Stale-While-Revalidate for non-HTML static assets
            event.respondWith(
              caches.match(request).then((cached) => {
                const networkFetch = fetch(request)
                  .then(async (response) => {
                    if (response && response.status === 200) {
                      const cache = await caches.open(SHELL_CACHE);
                      cache.put(request, response.clone());
                    }
                    return response;
                  })
                  .catch(() => cached);
                return cached || networkFetch;
              })
            );
          });
        JS
      end
    end
  end
end
