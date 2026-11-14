# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Renders Volunteer PWA pickup/dropoff stop cards with `✓ Confirm Pickup` / `✓ Confirm Delivery`
    # action buttons and prominent Member accessibility handoff instructions
    # (`Handoff: Walk up 4 porch steps & wait 60s at door`).
    class RouteStopCardCell < Decidim::ViewModel
      def show
        render :show
      end

      def stop_number
        fetch_attr(:stop_number, 1)
      end

      def stop_type_label
        type = fetch_attr(:stop_type, :pickup).to_s.upcase
        "STOP #{stop_number} • #{type}"
      end

      def confirmed?
        fetch_attr(:confirmed, false)
      end

      def confirmed_badge_text
        fetch_attr(:confirmed_badge_text, "✓ Confirmed 2:12 PM")
      end

      def action_button_label
        if fetch_attr(:stop_type, :pickup).to_sym == :dropoff
          fetch_attr(:button_label, "✓ Confirm Delivery")
        else
          fetch_attr(:button_label, "✓ Confirm Pickup")
        end
      end

      def dropoff?
        fetch_attr(:stop_type, :pickup).to_sym == :dropoff
      end

      def title
        fetch_attr(:title, "East Oakland Collective Pantry")
      end

      def subtitle_or_handoff
        fetch_attr(:subtitle, "7800 MacArthur Blvd • 4 Crates Loaded")
      end

      def parcel_summary
        fetch_attr(:parcel_summary, nil)
      end

      def window_recalc_note
        fetch_attr(:window_recalc_note, nil)
      end

      private

      def fetch_attr(key, default = nil)
        if model.respond_to?(key)
          val = model.public_send(key)
          val.nil? ? default : val
        elsif model.is_a?(Hash)
          val = model.key?(key) ? model[key] : model[key.to_s]
          val.nil? ? default : val
        else
          default
        end
      end
    end
  end
end
