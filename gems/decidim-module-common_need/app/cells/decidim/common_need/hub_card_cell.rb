# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Renders a Neighborhood Mutual Aid Hub card with badge, Member Audit score,
    # categories & PostGIS distance, and nested ItemCardCells.
    class HubCardCell < Decidim::ViewModel
      def show
        render :show
      end

      def badge_label
        fetch_attr(:badge_label, "NO MEANS-TESTING")
      end

      def audit_score_text
        score = fetch_attr(:member_audit_score, "4.9")
        "★ #{score} Member Audit"
      end

      def title
        fetch_attr(:title, "East Oakland Collective Pantry & Commons")
      end

      def subtitle_with_distance
        categories = fetch_attr(:categories_summary, "Food, Mutual Aid, Co-ops, Urban Garden & Pet Care")
        distance = fetch_attr(:distance_miles, "1.2")
        "#{categories} • #{distance} mi away"
      end

      def hub_label
        fetch_attr(:short_name, title)
      end

      def items
        fetch_attr(:items, [])
      end

      private

      def fetch_attr(key, default = nil)
        if model.respond_to?(key)
          model.public_send(key) || default
        elsif model.is_a?(Hash)
          model[key] || model[key.to_s] || default
        else
          default
        end
      end
    end
  end
end
