# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Background job triggered when a Volunteer Courier confirms an intermediate pickup stop
    # (e.g., Stop #2 at West County Sanctuary). Recalculates downstream ETAs via local OSRM
    # and broadcasts a low-data, zero-map-tile Turbo Stream update to the Member's Care Basket.
    class RecalculateRouteEtaJob < ActiveJob::Base
      queue_as :default

      def perform(delivery_id, stop_number = 2)
        recalculated = OsrmRoutingService.new.recalculate_after_stop_confirmation(stop_number: stop_number)
        delivery = find_delivery(delivery_id)

        if delivery
          update_delivery_and_downstream_stop(delivery, recalculated)
          broadcast_low_data_banner(delivery, recalculated)
        end

        recalculated
      end

      private

      def find_delivery(delivery_id)
        return nil unless defined?(Decidim::CommonNeed::Delivery) && delivery_id.present?

        Decidim::CommonNeed::Delivery.find_by(id: delivery_id)
      rescue StandardError
        nil
      end

      def update_delivery_and_downstream_stop(delivery, recalculated)
        delivery.update(
          window_headline: recalculated[:window_headline],
          milestone_step: recalculated[:milestone_step],
          state: "next_stop"
        )

        return unless delivery.respond_to?(:route_stops)

        stop_three = delivery.route_stops.find_by(stop_number: 3)
        stop_three&.update(scheduled_window: recalculated[:narrowed_window])
      end

      def broadcast_low_data_banner(delivery, recalculated)
        return unless defined?(Turbo::StreamsChannel)

        Turbo::StreamsChannel.broadcast_replace_to(
          "common_need_delivery_#{delivery.id}",
          target: "basket-delivery-updates-banner",
          html: "<div id='basket-delivery-updates-banner' data-milestone='#{recalculated[:milestone_step]}'>" \
                "#{recalculated[:window_headline]}</div>"
        )
      rescue StandardError
        nil
      end
    end
  end
end
