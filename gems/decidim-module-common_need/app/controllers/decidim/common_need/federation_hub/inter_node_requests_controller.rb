# frozen_string_literal: true

module Decidim
  module CommonNeed
    module FederationHub
      # Role 5 (Central Hub Federation PWA) Local Area Support Desk & Inter-Node Surplus Transfer controller.
      class InterNodeRequestsController < Decidim::CommonNeed::ApplicationController
        def index
          render json: {
            open_requests_count: 3,
            requests: [
              {
                code: "REQ #401 • INTER-NODE SURPLUS",
                priority: "HIGH PRIORITY",
                requesting_node: "Richmond / West County Node (#RCH-03)",
                need_summary: "400 N95 Masks & 20 Staple Grain Boxes"
              }
            ]
          }
        end

        def create
          render json: {
            status: "created",
            requesting_node: params[:requesting_node].presence || "#RCH-03",
            need_summary: params[:need_summary]
          }, status: :created
        end

        def approve_and_dispatch
          render json: {
            status: "fulfilled",
            request_id: params[:id],
            button_label: "✓ Fulfilled & Synced to Local Node"
          }
        end
      end
    end
  end
end
