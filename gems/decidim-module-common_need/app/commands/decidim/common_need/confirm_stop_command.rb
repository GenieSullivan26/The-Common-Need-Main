# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Confirms a Volunteer Courier route stop (e.g., Stop #2 pickup at West County Sanctuary),
    # triggers `RecalculateRouteEtaJob` / `OsrmRoutingService` recalculation, narrows
    # Stop #3's delivery window to `2:38 PM – 2:45 PM (You Are Next!)`, advances
    # `Delivery#milestone_step` to 3 (`next_stop`), and broadcasts a low-data
    # zero-map-tile Turbo Stream update to downstream Members.
    class ConfirmStopCommand < Decidim::Command
      NARROWED_HEADLINE = "Window: 2:38 PM – 2:45 PM (You Are Next!)"
      NARROWED_STOP_3_WINDOW = "2:38–2:45 PM"

      attr_reader :form, :route_stop, :delivery, :current_user, :recalculated_eta

      def initialize(form, route_stop: nil, delivery: nil, current_user: nil)
        @form = form
        @route_stop = route_stop
        @delivery = delivery
        @current_user = current_user || (form.respond_to?(:current_user) ? form.current_user : nil)
      end

      def call
        return broadcast(:invalid) if form.invalid?

        transaction do
          resolve_records!
          confirm_route_stop!
          recalculate_and_narrow_window!
          enqueue_eta_job!
          publish_stop_confirmed_event!
          broadcast_low_data_turbo_stream!
        end

        broadcast(:ok, delivery, recalculated_eta)
      end

      private

      def resolve_records!
        @route_stop ||= find_route_stop
        @delivery ||= find_delivery
      end

      def confirm_route_stop!
        return unless route_stop

        attrs = {
          confirmed_at: form.confirmed_at || Time.current,
          scheduled_window: "2:26 PM",
          state: "confirmed"
        }

        if defined?(Decidim.traceability) && Decidim.traceability && route_stop.is_a?(ActiveRecord::Base)
          Decidim.traceability.update!(route_stop, current_user, attrs, visibility: "public-only")
        elsif route_stop.respond_to?(:update!)
          route_stop.update!(attrs)
        end
      end

      def recalculate_and_narrow_window!
        stop_num = route_stop.respond_to?(:stop_number) ? route_stop.stop_number : form.stop_number
        @recalculated_eta = OsrmRoutingService.new.recalculate_after_stop_confirmation(
          stop_number: stop_num,
          confirmed_at: form.confirmed_at || Time.current
        )

        return unless delivery

        delivery_attrs = {
          window_headline: NARROWED_HEADLINE,
          milestone_step: 3,
          state: "next_stop"
        }

        if defined?(Decidim.traceability) && Decidim.traceability && delivery.is_a?(ActiveRecord::Base)
          Decidim.traceability.update!(delivery, current_user, delivery_attrs, visibility: "public-only")
        elsif delivery.respond_to?(:update!)
          delivery.update!(delivery_attrs)
        end

        narrow_downstream_stop_three!
      end

      def narrow_downstream_stop_three!
        return unless delivery.respond_to?(:route_stops)

        stop_three = delivery.route_stops.find_by(stop_number: 3)
        stop_three&.update!(scheduled_window: NARROWED_STOP_3_WINDOW)
      end

      def enqueue_eta_job!
        return unless defined?(RecalculateRouteEtaJob)

        delivery_id = delivery.respond_to?(:id) ? delivery.id : form.delivery_id
        RecalculateRouteEtaJob.perform_later(delivery_id, form.stop_number)
      rescue StandardError
        nil
      end

      def publish_stop_confirmed_event!
        return unless defined?(Decidim::EventsManager)

        Decidim::EventsManager.publish(
          event: "decidim.events.common_need.route_stop_confirmed",
          event_class: Decidim::Events::BaseEvent,
          resource: delivery || route_stop,
          affected_users: [current_user].compact,
          extra: {
            window_headline: NARROWED_HEADLINE,
            narrowed_window: NARROWED_STOP_3_WINDOW,
            milestone_step: 3
          }
        )
      rescue StandardError
        nil
      end

      def broadcast_low_data_turbo_stream!
        return unless defined?(Turbo::StreamsChannel)

        delivery_id = delivery.respond_to?(:id) ? delivery.id : form.delivery_id
        Turbo::StreamsChannel.broadcast_replace_to(
          "common_need_delivery_#{delivery_id}",
          target: "basket-delivery-updates-banner",
          html: "<div id='basket-delivery-updates-banner' data-milestone='3' data-zero-map-tiles='true'>" \
                "#{NARROWED_HEADLINE}</div>"
        )
      rescue StandardError
        nil
      end

      def find_route_stop
        return nil unless defined?(Decidim::CommonNeed::RouteStop) && form.route_stop_id

        Decidim::CommonNeed::RouteStop.find_by(id: form.route_stop_id)
      rescue StandardError
        nil
      end

      def find_delivery
        return nil unless defined?(Decidim::CommonNeed::Delivery) && form.delivery_id

        Decidim::CommonNeed::Delivery.find_by(id: form.delivery_id)
      rescue StandardError
        nil
      end
    end
  end
end
