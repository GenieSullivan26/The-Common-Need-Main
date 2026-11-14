# frozen_string_literal: true

module Decidim
  module CommonNeed
    module PartnerPortal
      # Manages incoming volunteer courier batches and crate staging at partner loading ramps.
      class BatchesController < Decidim::CommonNeed::ApplicationController
        def index
          render json: {
            batches: [
              {
                batch_code: "BATCH-OAK-409",
                eta: "Arriving in 4 mins",
                courier_name: "Marcus T. (Volunteer Courier Route)",
                households_count: 4,
                pull_summary: "4x Produce Bundles, 2x Staple Grain Boxes"
              },
              {
                batch_code: "BATCH-OAK-412",
                eta: "Pickup at 3:15 PM",
                courier_name: "Elena R. (Volunteer Courier Route)",
                households_count: 7,
                pull_summary: "6x Produce Bundles, 5x Sourdough Loaves, 3x Grain Boxes"
              }
            ]
          }
        end

        def verify_and_stage_crates
          render json: {
            status: "staged",
            batch_id: params[:id],
            button_label: "✓ Crates Verified & Staged"
          }
        end
      end
    end
  end
end
