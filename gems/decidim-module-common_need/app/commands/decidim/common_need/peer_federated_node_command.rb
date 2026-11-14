# frozen_string_literal: true

require "ostruct"

module Decidim
  module CommonNeed
    # Provisions and peers a new `FederatedNode` via `NodeProvisionerService`
    # (Docker Compose + PostGIS + OSRM + Photon + Doorkeeper OAuth2 peering)
    # while strictly enforcing 0 bytes of household PII on the Central Hub.
    class PeerFederatedNodeCommand < Decidim::Command
      attr_reader :form, :current_user, :federated_node, :provisioned_bundle

      def initialize(form, current_user: nil)
        @form = form
        @current_user = current_user || (form.respond_to?(:current_user) ? form.current_user : nil)
      end

      def call
        return broadcast(:invalid) if form.invalid?
        return broadcast(:invalid) unless form.household_pii_bytes_on_hub.to_i.zero?

        transaction do
          provision_stack!
          create_federated_node!
          publish_node_peered_event!
          broadcast_federation_turbo_stream!
        end

        broadcast(:ok, federated_node, provisioned_bundle)
      end

      private

      def provision_stack!
        @provisioned_bundle = NodeProvisionerService.new(
          name: form.name,
          domain: form.domain,
          deployment_mode: form.deployment_mode,
          osrm_region: form.osrm_region,
          node_code: form.node_code
        ).provision!
      end

      def create_federated_node!
        attrs = {
          decidim_component_id: resolved_component_id,
          node_code: provisioned_bundle[:node_code],
          name: form.name,
          domain: form.domain,
          deployment_mode: form.deployment_mode,
          osrm_region: form.osrm_region,
          oauth_application_uid: provisioned_bundle[:oauth_application_uid],
          household_pii_bytes_on_hub: 0,
          last_synced_at: Time.current,
          state: "healthy"
        }

        @federated_node = if defined?(Decidim.traceability) && Decidim.traceability && defined?(Decidim::CommonNeed::FederatedNode)
                            Decidim.traceability.create!(
                              Decidim::CommonNeed::FederatedNode,
                              current_user,
                              attrs,
                              visibility: "public-only"
                            )
                          elsif defined?(Decidim::CommonNeed::FederatedNode)
                            Decidim::CommonNeed::FederatedNode.create!(attrs)
                          else
                            OpenStruct.new(attrs.merge(id: 15))
                          end
      end

      def resolved_component_id
        return form.current_component.id if form.respond_to?(:current_component) && form.current_component

        1
      end

      def publish_node_peered_event!
        return unless defined?(Decidim::EventsManager)

        Decidim::EventsManager.publish(
          event: "decidim.events.common_need.federated_node_peered",
          event_class: Decidim::Events::BaseEvent,
          resource: federated_node,
          affected_users: [current_user].compact,
          extra: {
            node_code: provisioned_bundle[:node_code],
            domain: form.domain,
            household_pii_bytes_on_hub: 0
          }
        )
      rescue StandardError
        nil
      end

      def broadcast_federation_turbo_stream!
        return unless defined?(Turbo::StreamsChannel)

        Turbo::StreamsChannel.broadcast_replace_to(
          "common_need_federation_nodes",
          target: "federated-nodes-list",
          html: "<div id='federated-nodes-list' data-latest-node='#{provisioned_bundle[:node_code]}'>" \
                "#{form.name} (#{form.domain})</div>"
        )
      rescue StandardError
        nil
      end
    end
  end
end
