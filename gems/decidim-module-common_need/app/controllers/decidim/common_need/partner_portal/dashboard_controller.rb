# frozen_string_literal: true

module Decidim
  module CommonNeed
    module PartnerPortal
      # Role 3 (Partner Non-Profit PWA) dashboard & Local Node Accountability Ledger controller.
      class DashboardController < Decidim::CommonNeed::ApplicationController
        def show
          render json: {
            hub_title: "East Oakland Collective Pantry Hub",
            verification_badge: "LOCAL NODE 501(c)(3)",
            surplus_nourishment_monthly: "1,840 lbs / mo",
            staff_hours_reclaimed_weekly: "18.5 hrs / wk"
          }
        end

        def accountability
          render json: {
            component: "DECIDIM-ACCOUNTABILITY • LOCAL NODE",
            member_audit_score: "4.9 / 5.0",
            data_sovereignty: "Local Postgres Instance",
            node_code: current_local_node_code
          }
        end
      end
    end
  end
end
