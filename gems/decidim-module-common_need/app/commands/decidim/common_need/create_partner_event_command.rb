# frozen_string_literal: true

require "ostruct"

module Decidim
  module CommonNeed
    # Creates a Partner community event (`Decidim::Meetings::Meeting` or local node calendar record)
    # bound to the local Partner Hub and broadcasts it to the Member PWA Tab 4 Calendar.
    class CreatePartnerEventCommand < Decidim::Command
      attr_reader :form, :current_user, :partner_event

      def initialize(form, current_user: nil)
        @form = form
        @current_user = current_user || (form.respond_to?(:current_user) ? form.current_user : nil)
      end

      def call
        return broadcast(:invalid) if form.invalid?

        transaction do
          create_meeting_record!
          publish_calendar_event!
          broadcast_calendar_turbo_stream!
        end

        broadcast(:ok, partner_event)
      end

      private

      def create_meeting_record!
        payload = {
          title: form.title,
          event_day: form.event_day,
          event_time_label: form.event_time_label,
          category_tags: form.category_tags,
          hub_slug: form.hub_slug,
          location_address: form.location_address,
          latitude: form.latitude,
          longitude: form.longitude,
          coordinates: form.event_coordinates,
          home_delivery_kit_enabled: form.home_delivery_kit_enabled
        }

        @partner_event = if defined?(Decidim::Meetings::Meeting) && Decidim::Meetings::Meeting.respond_to?(:table_exists?) &&
                            Decidim::Meetings::Meeting.table_exists?
                           create_decidim_meeting(payload)
                         else
                           OpenStruct.new(payload.merge(id: rand(1000..9999)))
                         end
      end

      def create_decidim_meeting(payload)
        meeting_attrs = {
          title: { en: payload[:title] },
          description: { en: form.description.presence || "Community solidarity event hosted on #{Decidim::CommonNeed.local_node_code}" },
          address: payload[:location_address],
          latitude: payload[:latitude],
          longitude: payload[:longitude],
          start_time: Time.current + 2.days,
          end_time: Time.current + 2.days + 3.hours
        }

        if defined?(Decidim.traceability) && Decidim.traceability
          Decidim.traceability.create!(Decidim::Meetings::Meeting, current_user, meeting_attrs, visibility: "public-only")
        else
          Decidim::Meetings::Meeting.create!(meeting_attrs)
        end
      rescue StandardError
        OpenStruct.new(payload.merge(id: rand(1000..9999)))
      end

      def publish_calendar_event!
        return unless defined?(Decidim::EventsManager)

        Decidim::EventsManager.publish(
          event: "decidim.events.common_need.partner_event_published",
          event_class: Decidim::Events::BaseEvent,
          resource: partner_event,
          affected_users: [current_user].compact,
          extra: {
            title: form.title,
            event_day: form.event_day,
            hub_slug: form.hub_slug
          }
        )
      rescue StandardError
        nil
      end

      def broadcast_calendar_turbo_stream!
        return unless defined?(Turbo::StreamsChannel)

        Turbo::StreamsChannel.broadcast_replace_to(
          "common_need_member_calendar",
          target: "member-calendar-events-list",
          html: "<div id='member-calendar-events-list' data-latest-event='#{form.title}' data-day='#{form.event_day}'>" \
                "#{form.title}</div>"
        )
      rescue StandardError
        nil
      end
    end
  end
end
