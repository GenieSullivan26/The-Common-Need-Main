# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Claims a community bulk distribution shift in `TimebankEntry` for a Volunteer
    # Courier and records contributed timebank hours on the local node.
    class ClaimVolunteerShiftCommand < Decidim::Command
      attr_reader :timebank_entry, :current_user, :hours_contributed

      def initialize(timebank_entry, current_user:, hours_contributed: 2.0)
        @timebank_entry = timebank_entry
        @current_user = current_user
        @hours_contributed = hours_contributed.to_f
      end

      def call
        return broadcast(:invalid) if timebank_entry.nil? || current_user.nil?

        transaction do
          claim_shift_record!
          publish_shift_claimed_event!
          broadcast_shift_turbo_stream!
        end

        broadcast(:ok, timebank_entry)
      end

      private

      def claim_shift_record!
        attrs = {
          decidim_user_id: current_user.id,
          hours_contributed: hours_contributed.positive? ? hours_contributed : 2.0,
          state: "claimed"
        }

        if defined?(Decidim.traceability) && Decidim.traceability && timebank_entry.is_a?(ActiveRecord::Base)
          Decidim.traceability.update!(timebank_entry, current_user, attrs, visibility: "public-only")
        elsif timebank_entry.respond_to?(:update!)
          timebank_entry.update!(attrs)
        end
      end

      def publish_shift_claimed_event!
        return unless defined?(Decidim::EventsManager)

        Decidim::EventsManager.publish(
          event: "decidim.events.common_need.volunteer_shift_claimed",
          event_class: Decidim::Events::BaseEvent,
          resource: timebank_entry,
          affected_users: [current_user],
          extra: {
            hours_contributed: hours_contributed,
            node_code: Decidim::CommonNeed.local_node_code
          }
        )
      rescue StandardError
        nil
      end

      def broadcast_shift_turbo_stream!
        return unless defined?(Turbo::StreamsChannel)

        shift_id = timebank_entry.respond_to?(:id) ? timebank_entry.id : "shift"
        Turbo::StreamsChannel.broadcast_replace_to(
          "common_need_volunteer_shifts",
          target: "volunteer-shift-#{shift_id}",
          html: "<span id='volunteer-shift-#{shift_id}'>Signed Up ✓</span>"
        )
      rescue StandardError
        nil
      end
    end
  end
end
