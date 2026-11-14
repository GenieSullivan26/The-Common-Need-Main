# frozen_string_literal: true

Decidim.configure do |config|
  config.application_name = "The Common Need • Federated Mutual Aid Network"
  config.mailer_sender = "solidarity@commonneed.org"
  config.available_locales = [:en, :es]
  config.default_locale = :en
  config.enable_html_header_snippets = true
  config.track_newsletter_links = false

  # Self-hosted Local Node Map & Geocoding (Leaflet + Local OSRM + Photon)
  config.maps = {
    provider: :osm,
    api_key: nil,
    dynamic: {
      tile_layer: {
        url: ENV.fetch("OSM_TILE_LAYER_URL", "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"),
        attribution: "© OpenStreetMap contributors • Local Node OSRM"
      }
    },
    geocoding: {
      host: ENV.fetch("PHOTON_GEOCODER_HOST", "http://photon:2322")
    }
  }
end if defined?(Decidim) && Decidim.respond_to?(:configure)
