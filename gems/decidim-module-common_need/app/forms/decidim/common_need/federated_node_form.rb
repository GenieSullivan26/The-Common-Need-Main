# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Form object for provisioning and peering a new Federated Node in the Central Hub.
    # Enforces zero household PII bytes on the Central Hub (`household_pii_bytes_on_hub == 0`).
    class FederatedNodeForm < Decidim::Form
      mimic :federated_node

      DEPLOYMENT_MODES = [
        "Standalone Sovereign Docker",
        "Cooperative Multitenant Host"
      ].freeze

      OSRM_REGIONS = [
        "Bay Area / NorCal OSRM",
        "Central Valley OSRM",
        "Pacific NW OSRM"
      ].freeze

      attribute :name, String
      attribute :domain, String
      attribute :deployment_mode, String, default: "Standalone Sovereign Docker"
      attribute :osrm_region, String, default: "Bay Area / NorCal OSRM"
      attribute :household_pii_bytes_on_hub, Integer, default: 0
      attribute :node_code, String

      validates :name, presence: true
      validates :domain, presence: true
      validates :deployment_mode, presence: true
      validates :osrm_region, presence: true
      validates :household_pii_bytes_on_hub, presence: true, numericality: { equal_to: 0 }
      validate :enforce_zero_pii_on_hub!

      private

      def enforce_zero_pii_on_hub!
        return if household_pii_bytes_on_hub.to_i.zero?

        errors.add(:household_pii_bytes_on_hub, "must equal 0 bytes to preserve sovereign local node privacy")
      end
    end
  end
end
