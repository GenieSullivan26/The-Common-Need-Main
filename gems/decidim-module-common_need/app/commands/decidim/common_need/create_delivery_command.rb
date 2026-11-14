# frozen_string_literal: true

require "ostruct"

module Decidim
  module CommonNeed
    # Dispatches a multi-hub Care Basket delivery to the Volunteer Courier pool,
    # persists handoff preferences (`bring_up_porch_steps`, `wait_60s_at_door`),
    # computes the multi-stop route via `OsrmRoutingService`, creates the initial
    # `RouteStop` records, and broadcasts the low-data delivery banner.
    class CreateDeliveryCommand < Decidim::Command
      attr_reader :form, :care_basket, :current_user, :delivery

      def initialize(form, care_basket: nil, current_user: nil)
        @form = form
        @care_basket = care_basket
        @current_user = current_user || (form.respond_to?(:current_user) ? form.current_user : nil)
      end

      def call
        return broadcast(:invalid) if form.invalid?

        transaction do
          create_delivery!
          create_initial_route_stops!
          mark_basket_dispatched!
          publish_delivery_event!
          broadcast_turbo_stream!
        end

        broadcast(:ok, delivery)
      end

      private

      def create_delivery!
        route_data = OsrmRoutingService.new.compute_route
        attrs = delivery_attributes(route_data)

        @delivery = if defined?(Decidim.traceability) && Decidim.traceability && defined?(Decidim::CommonNeed::Delivery)
                      Decidim.traceability.create!(
                        Decidim::CommonNeed::Delivery,
                        current_user,
                        attrs,
                        visibility: "public-only"
                      )
                    elsif defined?(Decidim::CommonNeed::Delivery)
                      Decidim::CommonNeed::Delivery.create!(attrs)
                    else
                      OpenStruct.new(attrs.merge(id: 1))
                    end
      end

      def delivery_attributes(route_data)
        {
          decidim_component_id: resolved_component_id,
          decidim_common_need_care_basket_id: form.care_basket_id,
          decidim_user_id: current_user&.id,
          batch_code: "BATCH #OAK-409",
          shift_code: "SHIFT #OAK-409",
          route_title: "Deep East Oakland → Fruitvale Loop",
          window_headline: "Window: 2:35 PM – 2:50 PM (2 Stops Away)",
          bring_up_porch_steps: form.bring_up_porch_steps,
          wait_60s_at_door: form.wait_60s_at_door,
          handoff_instructions: form.handoff_summary,
          dropoff_block_label: form.dropoff_block_label,
          dropoff_coordinates: form.dropoff_coordinates,
          total_duration_minutes: route_data[:total_duration_minutes],
          total_distance_miles: route_data[:total_distance_miles],
          osrm_polyline: route_data[:polyline],
          osrm_maneuvers: route_data[:maneuvers],
          milestone_step: 2,
          state: "hubs_loaded"
        }
      end

      def create_initial_route_stops!
        return unless defined?(Decidim::CommonNeed::RouteStop) && delivery.respond_to?(:id)

        initial_stops_definitions.each do |stop_attrs|
          Decidim::CommonNeed::RouteStop.create!(
            stop_attrs.merge(decidim_common_need_delivery_id: delivery.id)
          )
        end
      end

      def initial_stops_definitions
        [
          {
            stop_number: 1,
            stop_type: "pickup",
            title: "East Oakland Collective Pantry",
            address_label: "7800 MacArthur Blvd • 4 Crates Loaded",
            manifest_summary: "Organic Collard Greens, 25lb Grain Box & Sourdough",
            scheduled_window: "2:12 PM",
            confirmed_at: Time.current,
            state: "confirmed"
          },
          {
            stop_number: 2,
            stop_type: "pickup",
            title: "West County Mutual Aid Care Hub",
            address_label: "3115 San Pablo Ave (By 2:30 PM)",
            manifest_summary: "2 sealed medical/hygiene parcels (N95 Masks & Care Kits)",
            scheduled_window: "Est. 2:28 PM",
            state: "pending"
          },
          {
            stop_number: 3,
            stop_type: "dropoff",
            title: "Member Household • #{form.dropoff_block_label}",
            address_label: form.dropoff_block_label,
            handoff_note: form.handoff_summary,
            scheduled_window: "2:35–2:50 PM",
            coordinates: form.dropoff_coordinates,
            state: "pending"
          }
        ]
      end

      def mark_basket_dispatched!
        target_basket = care_basket || find_care_basket
        return unless target_basket.respond_to?(:update!)

        target_basket.update!(
          bring_up_porch_steps: form.bring_up_porch_steps,
          wait_60s_at_door: form.wait_60s_at_door,
          state: "dispatched"
        )
      end

      def find_care_basket
        return nil unless defined?(Decidim::CommonNeed::CareBasket) && form.care_basket_id

        Decidim::CommonNeed::CareBasket.find_by(id: form.care_basket_id)
      rescue StandardError
        nil
      end

      def resolved_component_id
        return care_basket.decidim_component_id if care_basket.respond_to?(:decidim_component_id)
        return form.current_component.id if form.respond_to?(:current_component) && form.current_component

        1
      end

      def publish_delivery_event!
        return unless defined?(Decidim::EventsManager)

        Decidim::EventsManager.publish(
          event: "decidim.events.common_need.delivery_dispatched",
          event_class: Decidim::Events::BaseEvent,
          resource: delivery,
          affected_users: [current_user].compact,
          extra: {
            batch_code: "BATCH #OAK-409",
            handoff_instructions: form.handoff_summary
          }
        )
      rescue StandardError
        nil
      end

      def broadcast_turbo_stream!
        return unless defined?(Turbo::StreamsChannel) && delivery.respond_to?(:id)

        Turbo::StreamsChannel.broadcast_replace_to(
          "common_need_delivery_#{delivery.id}",
          target: "basket-delivery-updates-banner",
          html: "<div id='basket-delivery-updates-banner'>#{delivery.window_headline}</div>"
        )
      rescue StandardError
        nil
      end
    end
  end
end
