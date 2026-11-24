# frozen_string_literal: true

module Decidim
  module CommonNeed
    module PartnerPortal
      # Allows verified 501(c)(3) partners to post real-time surplus goods to the local node catalog.
      class SurplusItemsController < Decidim::CommonNeed::ApplicationController
        def index
          base_items = [
            { name: "Organic Collard Greens & Kale Bundle", tags: "Vegan / GF • Local Node #1", stock_quantity: 24 },
            { name: "25lb Staple Grain Box (Rice, Pinto Beans)", tags: "Halal / Kosher • Local Node #1", stock_quantity: 15 }
          ]
          live_posted = Decidim::CommonNeed::ResourceNavigatorService.registered_live_surplus_items(node_code: current_local_node_code).map do |i|
            { name: i[:title], tags: i[:tags_summary], stock_quantity: i[:stock_quantity] }
          end
          render json: { items: live_posted + base_items }
        end

        def create
          name = params[:name].presence || "Fresh Bok Choy & Ginger Bundle"
          qty = (params[:quantity] || 20).to_i
          category = params[:category].presence || "food"

          registered = Decidim::CommonNeed::ResourceNavigatorService.register_live_surplus_item!(
            name: name,
            stock_quantity: qty,
            category: category,
            node_code: current_local_node_code
          )

          render json: {
            status: "created",
            name: name,
            stock_quantity: qty,
            category: registered[:category],
            tags: "Fresh Surplus • Local Node #1"
          }, status: :created
        end
      end
    end
  end
end
