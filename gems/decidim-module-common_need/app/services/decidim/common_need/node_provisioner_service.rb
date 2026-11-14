# frozen_string_literal: true

require "securerandom"

module Decidim
  module CommonNeed
    # Generates a turn-key sovereign Docker Compose stack (Decidim v0.32 + PostgreSQL/PostGIS +
    # local OSRM routing server + Photon offline geocoder + Doorkeeper OAuth2 peering)
    # for emerging communities joining The Common Need federation.
    class NodeProvisionerService
      attr_reader :name, :domain, :deployment_mode, :osrm_region, :node_code

      def initialize(name:, domain:, deployment_mode: "Standalone Sovereign Docker", osrm_region: "Bay Area / NorCal OSRM", node_code: nil)
        @name = name
        @domain = domain
        @deployment_mode = deployment_mode
        @osrm_region = osrm_region
        @node_code = node_code.presence || generate_node_code
      end

      def provision!
        oauth_uid = "doorkeeper-#{node_code.downcase.delete("#")}-#{SecureRandom.hex(6)}"
        {
          node_code: node_code,
          name: name,
          domain: domain,
          deployment_mode: deployment_mode,
          osrm_region: osrm_region,
          oauth_application_uid: oauth_uid,
          household_pii_bytes_on_hub: 0,
          stack_version: "Decidim v0.32 + PostGIS 3.4 + OSRM 5.27 + Photon",
          docker_compose_yaml: generate_docker_compose(oauth_uid),
          state: "healthy"
        }
      end

      def generate_docker_compose(oauth_uid = "doorkeeper-peer")
        <<~YAML
          version: "3.9"
          services:
            decidim_node:
              image: ghcr.io/the-common-need/decidim-common-need:0.32.0
              environment:
                NODE_CODE: "#{node_code}"
                NODE_NAME: "#{name}"
                DECIDIM_HOST: "#{domain}"
                DEPLOYMENT_MODE: "#{deployment_mode}"
                LOCAL_OSRM_URL: "http://osrm_router:5000"
                PHOTON_GEOCODER_URL: "http://photon_geocoder:2322"
                LOCAL_OLLAMA_URL: "http://127.0.0.1:11434/api/generate"
                DOORKEEPER_FEDERATION_UID: "#{oauth_uid}"
                HOUSEHOLD_PII_BYTES_ON_HUB: "0"
              depends_on:
                - postgis_db
                - osrm_router
                - photon_geocoder
            postgis_db:
              image: postgis/postgis:16-3.4-alpine
              environment:
                POSTGRES_DB: decidim_common_need_production
            osrm_router:
              image: ghcr.io/project-osrm/osrm-backend:latest
              environment:
                OSRM_REGION: "#{osrm_region}"
            photon_geocoder:
              image: rtuszik/photon-docker:latest
              environment:
                REGION: "#{osrm_region}"
        YAML
      end

      private

      def generate_node_code
        prefix = name.to_s.gsub(/[^A-Za-z]/, "").upcase[0, 3].presence || "NOD"
        "##{prefix}-#{rand(10..99)}"
      end
    end
  end
end
