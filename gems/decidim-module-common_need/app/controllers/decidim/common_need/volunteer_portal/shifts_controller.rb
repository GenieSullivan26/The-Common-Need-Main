# frozen_string_literal: true

module Decidim
  module CommonNeed
    module VolunteerPortal
      # Manages Community Bulk Distribution Shifts (`decidim-meetings`) for Role 2 (Volunteer PWA).
      class ShiftsController < Decidim::CommonNeed::ApplicationController
        def index
          render json: {
            node_code: current_local_node_code,
            shifts: [
              {
                id: "oak-409",
                title: "Thu 2:00 PM • East Oakland Loop",
                subtitle: "Pickup at 7800 MacArthur Blvd • 4 Households (4.6 mi)",
                status: "Signed Up ✓"
              },
              {
                id: "oak-415",
                title: "Sat 10:00 AM • Fruitvale & San Antonio Loop",
                subtitle: "Pickup at 3301 E 12th St • 5 Households (2.1 mi)",
                status: "Open"
              }
            ]
          }
        end

        def claim_shift
          render json: {
            status: "claimed",
            shift_id: params[:id],
            badge: "Signed Up ✓"
          }
        end
      end
    end
  end
end
