# frozen_string_literal: true

module Decidim
  module CommonNeed
    module PartnerPortal
      # Allows verified 501(c)(3) partners to post real-time surplus goods to the local node catalog.
      class SurplusItemsController < Decidim::CommonNeed::ApplicationController
        def index
          render json: {
            items: [
              { name: "Organic Collard Greens & Kale Bundle", tags: "Vegan / GF • Local Node #1", stock_quantity: 24 },
              { name: "25lb Staple Grain Box (Rice, Pinto Beans)", tags: "Halal / Kosher • Local Node #1", stock_quantity: 15 }
            ]
          }
        end

        def create
          name = params[:name].presence || "Fresh Bok Choy & Ginger Bundle"
          qty = (params[:quantity] || 20).to_i

          render json: {
            status: "created",
            name: name,
            stock_quantity: qty,
            tags: "Fresh Surplus • Local Node #1"
          }, status: :created
        end
      end
    end
  end
end
