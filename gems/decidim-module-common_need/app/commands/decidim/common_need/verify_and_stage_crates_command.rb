# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Marks `crates_staged_at_ramp = true` on a `Delivery` batch at the Partner
    # Non-Profit loading ramp (Role 3 Tab 1: Handoff).
    class VerifyAndStageCratesCommand < Decidim::Command
      attr_reader :delivery, :current_user

      def initialize(delivery, current_user: nil)
        @delivery = delivery
        @current_user = current_user
      end

      def call
        return broadcast(:invalid) if delivery.nil?

        transaction do
          stage_crates_at_ramp!
          publish_crates_staged_event!
          broadcast_ramp_turbo_stream!
        end

        broadcast(:ok, delivery)
      end

      private

      def stage_crates_at_ramp!
        attrs = { crates_staged_at_ramp: true }

        if defined?(Decidim.traceability) && Decidim.traceability && delivery.is_a?(ActiveRecord::Base)
          Decidim.traceability.update!(delivery, current_user, attrs, visibility: "public-only")
        elsif delivery.respond_to?(:update!)
          delivery.update!(attrs)
        elsif delivery.respond_to?(:crates_staged_at_ramp=)
          delivery.crates_staged_at_ramp = true
        end
      end

      def publish_crates_staged_event!
        return unless defined?(Decidim::EventsManager)

        Decidim::EventsManager.publish(
          event: "decidim.events.common_need.crates_staged_at_ramp",
          event_class: Decidim::Events::BaseEvent,
          resource: delivery,
          affected_users: [current_user].compact,
          extra: {
            batch_code: delivery.respond_to?(:batch_code) ? delivery.batch_code : "BATCH #OAK-409",
            crates_staged_at_ramp: true
          }
        )
      rescue StandardError
        nil
      end

      def broadcast_ramp_turbo_stream!
        return unless defined?(Turbo::StreamsChannel)

        delivery_id = delivery.respond_to?(:id) ? delivery.id : "oak_409"
        Turbo::StreamsChannel.broadcast_replace_to(
          "common_need_partner_ramp",
          target: "batch-stage-btn-#{delivery_id}",
          html: "<span id='batch-stage-btn-#{delivery_id}'>✓ Crates Verified & Staged</span>"
        )
      rescue StandardError
        nil
      end
    end
  end
end
