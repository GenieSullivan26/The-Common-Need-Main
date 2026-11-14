# frozen_string_literal: true

require "ostruct"

module Decidim
  module CommonNeed
    # Creates a new `Decidim::Services::ServiceItem` with PostGIS `pickup_coordinates`,
    # increments the Partner Hub's monthly surplus nourishment metrics, and broadcasts
    # a Turbo Stream update to the Member PWA Catalog.
    class PostSurplusItemCommand < Decidim::Command
      attr_reader :form, :hub, :current_user, :service_item

      def initialize(form, hub: nil, current_user: nil)
        @form = form
        @hub = hub
        @current_user = current_user || (form.respond_to?(:current_user) ? form.current_user : nil)
      end

      def call
        return broadcast(:invalid) if form.invalid?

        transaction do
          resolve_hub!
          create_service_item!
          update_hub_surplus_metrics!
          publish_surplus_posted_event!
          broadcast_catalog_turbo_stream!
        end

        broadcast(:ok, service_item)
      end

      private

      def resolve_hub!
        @hub ||= Decidim::CommonNeed::Hub.find_by(id: form.hub_id) if defined?(Decidim::CommonNeed::Hub) && form.hub_id
      rescue StandardError
        @hub = nil
      end

      def create_service_item!
        attrs = service_item_attributes

        @service_item = if defined?(Decidim.traceability) && Decidim.traceability && defined?(Decidim::Services::ServiceItem)
                          Decidim.traceability.create!(
                            Decidim::Services::ServiceItem,
                            current_user,
                            attrs,
                            visibility: "public-only"
                          )
                        elsif defined?(Decidim::Services::ServiceItem)
                          Decidim::Services::ServiceItem.create!(attrs)
                        else
                          OpenStruct.new(attrs.merge(id: 1))
                        end
      end

      def service_item_attributes
        tags = Array(form.dietary_and_safety_tags).join(" • ").presence || "Fresh Surplus • Local Node #1"
        {
          decidim_component_id: resolved_component_id,
          decidim_common_need_hub_id: hub&.id || form.hub_id,
          decidim_author_id: current_user&.id || 1,
          decidim_author_type: current_user ? current_user.class.name : "Decidim::UserBaseEntity",
          category_key: form.category_key,
          title: form.title,
          dietary_and_safety_tags: tags,
          stock_quantity: form.stock_quantity,
          weight_lbs: form.weight_lbs || 25.0,
          pickup_coordinates: form.pickup_coordinates,
          interaction_mode: "add_share",
          cta_label: "+ Add Share",
          state: "available"
        }
      end

      def update_hub_surplus_metrics!
        return unless hub.respond_to?(:surplus_nourishment_lbs_monthly) && hub.respond_to?(:update!)

        added_lbs = (form.weight_lbs || 25.0).to_i
        hub.update!(surplus_nourishment_lbs_monthly: hub.surplus_nourishment_lbs_monthly.to_i + added_lbs)
      end

      def resolved_component_id
        return hub.decidim_component_id if hub.respond_to?(:decidim_component_id)
        return form.current_component.id if form.respond_to?(:current_component) && form.current_component

        1
      end

      def publish_surplus_posted_event!
        return unless defined?(Decidim::EventsManager)

        Decidim::EventsManager.publish(
          event: "decidim.events.common_need.surplus_item_posted",
          event_class: Decidim::Events::BaseEvent,
          resource: service_item,
          affected_users: [current_user].compact,
          extra: {
            category_key: form.category_key,
            stock_quantity: form.stock_quantity
          }
        )
      rescue StandardError
        nil
      end

      def broadcast_catalog_turbo_stream!
        return unless defined?(Turbo::StreamsChannel)

        Turbo::StreamsChannel.broadcast_replace_to(
          "common_need_member_catalog",
          target: "live-inventory-list",
          html: "<div id='live-inventory-list' data-latest-item='#{form.title}'>#{form.stock_quantity} left</div>"
        )
      rescue StandardError
        nil
      end
    end
  end
end
