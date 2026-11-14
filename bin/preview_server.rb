#!/usr/bin/env ruby
# frozen_string_literal: true

require "socket"
require "json"
require "uri"

$LOAD_PATH.unshift File.expand_path("../gems/decidim-module-common_need/lib", __dir__)
$LOAD_PATH.unshift File.expand_path("../gems/decidim-module-common_need/app/services", __dir__)

module Decidim
  module CommonNeed
    def self.local_osrm_endpoint
      ENV.fetch("LOCAL_OSRM_URL", "http://127.0.0.1:5000")
    end

    def self.local_node_code
      ENV.fetch("LOCAL_NODE_CODE", "#OAK-01")
    end
  end
end

require "decidim/common_need/version"
require "decidim/common_need/osrm_routing_service"
require "decidim/common_need/federation_telemetry_service"

PORT = Integer(ENV.fetch("PORT", 8080))
ROOT_DIR = File.expand_path("..", __dir__)
PREVIEW_HTML_PATH = File.join(ROOT_DIR, "the_common_need_pwa_preview.html")

ROLE_PATH_MAP = {
  "/member" => "member",
  "/volunteer" => "volunteer",
  "/partner" => "nonprofit",
  "/nonprofit" => "nonprofit",
  "/local_node" => "localnode",
  "/federation" => "network"
}.freeze

MANIFEST_JSON = JSON.pretty_generate(
  name: "The Common Need • Federated Mutual Aid Network",
  short_name: "CommonNeed",
  description: "Offline-First 5-Role Federated Mutual Aid PWA Suite (Decidim v0.32+)",
  start_url: "/",
  display: "standalone",
  background_color: "#120924",
  theme_color: "#95C623",
  orientation: "portrait-primary"
)

SERVICE_WORKER_JS = <<~JS
  const CACHE_NAME = "common-need-pwa-v0.32.4";
  const OFFLINE_URLS = ["/", "/manifest.json", "/volunteer/routes/OAK-409/offline_bundle.json"];

  self.addEventListener("install", (event) => {
    event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(OFFLINE_URLS)));
    self.skipWaiting();
  });

  self.addEventListener("fetch", (event) => {
    event.respondWith(
      caches.match(event.request).then((cached) => cached || fetch(event.request))
    );
  });
JS

server = TCPServer.new("0.0.0.0", PORT)
$stdout.sync = true
puts "The Common Need 5-Role PWA Preview Server listening on port #{PORT}..."

loop do
  client = server.accept
  Thread.new(client) do |conn|
    request_line = conn.gets
    next unless request_line

    _method, full_path, _http_ver = request_line.split(" ")
    while (line = conn.gets) && line != "\r\n"
      # consume headers
    end

    uri = URI.parse(full_path || "/")
    path = uri.path
    query_params = URI.decode_www_form(uri.query.to_s).to_h

    status = "200 OK"
    content_type = "text/html; charset=utf-8"
    body = ""

    case path
    when "/manifest.json"
      content_type = "application/manifest+json; charset=utf-8"
      body = MANIFEST_JSON
    when "/service-worker.js"
      content_type = "application/javascript; charset=utf-8"
      body = SERVICE_WORKER_JS
    when "/federation/telemetry.json"
      content_type = "application/json; charset=utf-8"
      body = JSON.pretty_generate(Decidim::CommonNeed::FederationTelemetryService.new.call)
    when "/volunteer/routes/OAK-409/offline_bundle.json"
      content_type = "application/json; charset=utf-8"
      body = JSON.pretty_generate(Decidim::CommonNeed::OsrmRoutingService.new.offline_route_bundle)
    else
      html = File.read(PREVIEW_HTML_PATH)
      requested_role = ROLE_PATH_MAP[path] || query_params["role"]
      if %w[member volunteer nonprofit localnode network].include?(requested_role)
        boot_script = "<script>window.addEventListener('DOMContentLoaded', () => switchRole('#{requested_role}'));</script></body>"
        html = html.sub("</body>", boot_script)
      end
      body = html
    end

    headers = [
      "HTTP/1.1 #{status}",
      "Content-Type: #{content_type}",
      "Content-Length: #{body.bytesize}",
      "Cache-Control: no-cache",
      "Connection: close",
      "",
      ""
    ].join("\r\n")

    conn.write(headers)
    conn.write(body)
  rescue StandardError => e
    warn "Request error: #{e.message}"
  ensure
    conn&.close
  end
end
