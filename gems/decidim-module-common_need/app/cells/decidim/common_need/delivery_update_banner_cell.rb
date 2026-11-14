# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Renders the expandable top `⏱️ DELIVERY UPDATES` banner on the Member Care Basket:
    # - `SHIFT #OAK-409`
    # - `LOW-DATA DYNAMIC WINDOW • ZERO MAP TILES`
    # - Dynamic arrival window (`2:35 PM – 2:50 PM` narrowing to `2:38 PM – 2:45 PM (You Are Next!)`)
    # - 4-step milestone progress bar (`1. Shift Claimed ✓`, `2. Hubs Loaded ✓`, `3. Next Stop`, `4. Delivered`)
    # - Chronological stop logs
    class DeliveryUpdateBannerCell < Decidim::ViewModel
      def show
        render :show
      end

      def shift_code
        fetch_attr(:shift_code, "SHIFT #OAK-409")
      end

      def narrowed?
        fetch_attr(:narrowed, false)
      end

      def window_headline
        if narrowed?
          fetch_attr(:window_headline, "Window: 2:38 PM – 2:45 PM (You Are Next!)")
        else
          fetch_attr(:window_headline, "Window: 2:35 PM – 2:50 PM (2 Stops Away)")
        end
      end

      def expanded_window_title
        if narrowed?
          fetch_attr(:expanded_window_title, "Next Stop! Arriving 2:38 PM – 2:45 PM")
        else
          fetch_attr(:expanded_window_title, "Arriving Today, 2:35 PM – 2:50 PM")
        end
      end

      def expanded_stops_away
        if narrowed?
          fetch_attr(:expanded_stops_away, "● Volunteer Marcus just completed Stop #2 — heading to your block now!")
        else
          fetch_attr(:expanded_stops_away, "● Your household is 2 stops away (Stop #3 of 4 on Volunteer Marcus's route)")
        end
      end

      def handoff_note
        fetch_attr(:handoff_note, "Handoff: Walk up 4 porch steps & wait 60s")
      end

      def household_window_range
        narrowed? ? "2:38–2:45 PM" : "2:35–2:50 PM"
      end

      def expanded_by_default?
        fetch_attr(:expanded, false)
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
