# frozen_string_literal: true

module Decidim
  module CommonNeed
    # ActionCable / Turbo Stream channel for real-time low-data text updates
    # on the Member Care Basket (`LOW-DATA DYNAMIC WINDOW • ZERO MAP TILES`).
    class DeliveryWindowChannel < ::ApplicationCable::Channel
      STREAM_PREFIX = "common_need_delivery_window"

      def subscribed
        shift_code = params[:shift_code].presence || "OAK-409"
        stream_from "#{STREAM_PREFIX}:#{shift_code}"
      end

      def unsubscribed
        stop_all_streams
      end

      # Broadcasts a low-data arrival window update (zero map tiles) to subscribed households.
      def self.broadcast_window_update(shift_code: "OAK-409", stop_number: 2, narrowed: true)
        payload = {
          shift_code: "SHIFT ##{shift_code}",
          stop_confirmed: stop_number,
          narrowed: narrowed,
          window_headline: narrowed ? "Window: 2:38 PM – 2:45 PM (You Are Next!)" : "Window: 2:35 PM – 2:50 PM (2 Stops Away)",
          expanded_window_title: narrowed ? "Next Stop! Arriving 2:38 PM – 2:45 PM" : "Arriving Today, 2:35 PM – 2:50 PM",
          expanded_stops_away: narrowed ? "● Volunteer Marcus just completed Stop ##{stop_number} — heading to your block now!" : "● Your household is 2 stops away (Stop #3 of 4 on Volunteer Marcus's route)",
          household_window_range: narrowed ? "2:38–2:45 PM" : "2:35–2:50 PM",
          milestone_step_3_label: narrowed ? "3. Next Stop ✓" : "3. Next Stop",
          zero_map_tiles: true,
          broadcasted_at: Time.current.iso8601
        }

        ActionCable.server.broadcast("#{STREAM_PREFIX}:#{shift_code}", payload)

        if defined?(Turbo::StreamsChannel)
          Turbo::StreamsChannel.broadcast_replace_to(
            "#{STREAM_PREFIX}_turbo:#{shift_code}",
            target: "basket-delivery-banner",
            html: Decidim::ViewModel.cell("decidim/common_need/delivery_update_banner", payload.merge(expanded: true)).call.to_s
          )
        end

        payload
      end
    end
  end
end
