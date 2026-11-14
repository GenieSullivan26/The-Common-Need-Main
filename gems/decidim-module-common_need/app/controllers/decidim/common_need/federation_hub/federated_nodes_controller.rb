# frozen_string_literal: true

module Decidim
  module CommonNeed
    module FederationHub
      # Role 5 (Central Hub Federation PWA) Federated Server Incubator & Peering controller.
      class FederatedNodesController < Decidim::CommonNeed::ApplicationController
        def index
          render json: {
            peered_nodes_count: 14,
            nodes: [
              {
                code: "#OAK-01",
                name: "East Oakland Node",
                status: "● HEALTHY (18ms)",
                summary: "Sovereign Postgres + Local OSRM • 4 Hubs • 312 Households"
              }
            ]
          }
        end

        def create
          name = params[:name].presence || "Richmond & San Pablo Node"
          domain = params[:domain].presence || "richmond.commonneed.org"
          mode = params[:deployment_mode].presence || "Standalone Sovereign Docker"
          osm_region = params[:osrm_region].presence || "Bay Area / NorCal OSRM"

          render json: {
            status: "peered_and_live",
            code: "#NODE-15",
            name: name,
            domain: domain,
            deployment_mode: mode,
            osrm_region: osm_region
          }, status: :created
        end

        def sync_all
          render json: {
            status: "synced",
            nodes_synced: 14,
            release: "decidim-module-courier v0.32.4"
          }
        end
      end
    end
  end
end
