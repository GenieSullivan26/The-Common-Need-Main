# frozen_string_literal: true

module Decidim
  module CommonNeed
    module LocalNodeAdmin
      # Role 4 (Local Node Admin PWA) Community-Relevant Analytics controller.
      class AnalyticsController < Decidim::CommonNeed::ApplicationController
        def show
          render json: {
            node_code: current_local_node_code,
            active_neighborhood_hubs: "4 Community Hubs",
            households_served_monthly: "312 Families",
            volunteer_shift_fill_rate: "94.2%",
            surplus_nourishment_monthly: "1,840 lbs / mo"
          }
        end
      end
    end
  end
end
