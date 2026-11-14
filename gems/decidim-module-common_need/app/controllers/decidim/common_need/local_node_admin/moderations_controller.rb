# frozen_string_literal: true

module Decidim
  module CommonNeed
    module LocalNodeAdmin
      # Handles Member Request & Content Moderation (`Decidim::Moderation`) on the Local Node PWA.
      class ModerationsController < Decidim::CommonNeed::ApplicationController
        def index
          render json: {
            node_code: current_local_node_code,
            flagged_items: [
              {
                id: "west-county-pharmacy-flag",
                title: "Flagged Review on West County Pharmacy",
                reason: "Reported as incorrect address tag by courier",
                status: "open"
              }
            ]
          }
        end

        def resolve_flag
          render json: {
            status: "resolved",
            moderation_id: params[:id],
            badge: "✓ Resolved",
            logged_in_admin_activity: true
          }
        end
      end
    end
  end
end
