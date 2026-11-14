# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Represents an autonomous local Decidim + PostGIS + OSRM server peered to The Common Need Federation.
    # Strictly enforces Zero-Knowledge Federation: household PII bytes on the Central Hub must always equal 0.
    class FederatedNode < Decidim::CommonNeed::ApplicationRecord
      include Decidim::HasComponent
      include Decidim::Traceable
      include Decidim::Loggable
      include AASM

      self.table_name = "decidim_common_need_federated_nodes"

      component_manifest_name "common_need"

      validates :node_code, presence: true, uniqueness: true
      validates :name, presence: true
      validates :domain, presence: true, uniqueness: true
      validates :household_pii_bytes_on_hub, numericality: { equal_to: 0 }

      aasm column: :state do
        state :incubating
        state :healthy, initial: true
        state :peered
        state :offline

        event :activate_peer do
          transitions from: [:incubating, :offline, :healthy, :peered], to: :peered
        end

        event :mark_healthy do
          transitions from: [:incubating, :peered, :offline, :healthy], to: :healthy
        end

        event :mark_offline do
          transitions from: [:incubating, :peered, :healthy], to: :offline
        end
      end

      def zero_knowledge_telemetry_payload
        {
          node_code: node_code,
          name: name,
          domain: domain,
          deployment_mode: deployment_mode,
          osrm_region: osrm_region,
          active_hubs_count: active_hubs_count,
          households_served_monthly: households_served_monthly,
          shift_fill_rate_pct: shift_fill_rate_pct.to_f,
          surplus_rescued_lbs: surplus_rescued_lbs,
          latency_ms: latency_ms,
          household_pii_bytes: 0,
          household_pii_bytes_on_hub: 0,
          state: state,
          last_synced_at: (last_synced_at || Time.current).iso8601
        }
      end
    end
  end
end
