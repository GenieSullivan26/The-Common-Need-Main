# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Fulfills an `InterNodeRequest` from the Central Hub Area Support Desk
    # (e.g., REQ #401 routing 400 N95 Masks & 20 Staple Grain Boxes from
    # `#OAK-01` & `#BER-04` to Richmond `#RCH-03`).
    class DispatchInterNodeTransferCommand < Decidim::Command
      attr_reader :form, :inter_node_request, :current_user

      def initialize(form, inter_node_request: nil, current_user: nil)
        @form = form
        @inter_node_request = inter_node_request
        @current_user = current_user || (form.respond_to?(:current_user) ? form.current_user : nil)
      end

      def call
        return broadcast(:invalid) if form.invalid?

        transaction do
          resolve_inter_node_request!
          return broadcast(:invalid) if inter_node_request.nil?

          mark_request_dispatched!
          publish_transfer_event!
          broadcast_transfer_turbo_stream!
        end

        broadcast(:ok, inter_node_request)
      end

      private

      def resolve_inter_node_request!
        return if @inter_node_request

        @inter_node_request = if defined?(Decidim::CommonNeed::InterNodeRequest) && form.inter_node_request_id
                                Decidim::CommonNeed::InterNodeRequest.find_by(id: form.inter_node_request_id)
                              end
      rescue StandardError
        @inter_node_request = nil
      end

      def mark_request_dispatched!
        attrs = {
          source_node_codes: Array(form.source_node_codes),
          dispatched_at: Time.current,
          state: "fulfilled"
        }

        if defined?(Decidim.traceability) && Decidim.traceability && inter_node_request.is_a?(ActiveRecord::Base)
          Decidim.traceability.update!(inter_node_request, current_user, attrs, visibility: "public-only")
        elsif inter_node_request.respond_to?(:update!)
          inter_node_request.update!(attrs)
        end
      end

      def publish_transfer_event!
        return unless defined?(Decidim::EventsManager)

        Decidim::EventsManager.publish(
          event: "decidim.events.common_need.inter_node_transfer_dispatched",
          event_class: Decidim::Events::BaseEvent,
          resource: inter_node_request,
          affected_users: [current_user].compact,
          extra: {
            request_code: form.request_code,
            source_node_codes: form.source_node_codes,
            target_node_code: form.target_node_code,
            manifest_summary: form.manifest_summary
          }
        )
      rescue StandardError
        nil
      end

      def broadcast_transfer_turbo_stream!
        return unless defined?(Turbo::StreamsChannel)

        req_id = inter_node_request.respond_to?(:id) ? inter_node_request.id : form.inter_node_request_id
        Turbo::StreamsChannel.broadcast_replace_to(
          "common_need_federation_requests",
          target: "area-req-#{req_id}",
          html: "<div id='area-req-#{req_id}'>✓ Fulfilled & Synced to Local Node</div>"
        )
      rescue StandardError
        nil
      end
    end
  end
end
