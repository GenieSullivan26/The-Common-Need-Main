# frozen_string_literal: true

module Decidim
  module CommonNeed
    module LocalNodeAdmin
      # Manages 501(c)(3) partner organization onboarding & moderation on the Local Node PWA.
      class PartnerApplicationsController < Decidim::CommonNeed::ApplicationController
        def index
          render json: {
            node_code: current_local_node_code,
            applications: [
              {
                id: "fruitvale-senior-lunch",
                organization_name: "Fruitvale Senior Lunch Project (Pending 501c3)",
                ein: "94-7728190",
                submitted_on: "Oct 28",
                status: "pending"
              }
            ]
          }
        end

        def create
          render json: {
            status: "invited",
            organization_name: params[:organization_name].presence || "San Antonio Mutual Aid",
            ein: params[:ein].presence || "94-1234567",
            workflow: "Decidim::Verifications::NonProfitHandler"
          }, status: :created
        end

        def approve
          render json: {
            status: "approved",
            application_id: params[:id],
            badge: "✓ Approved on Node"
          }
        end

        def hold
          render json: {
            status: "held",
            application_id: params[:id],
            reason: "Placed on hold for Member Assembly review"
          }
        end
      end
    end
  end
end
