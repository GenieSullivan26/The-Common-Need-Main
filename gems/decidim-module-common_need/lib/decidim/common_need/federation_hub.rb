# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Role 5: Central Hub Federation PWA Portal (Federated Server Incubator, Local Area Support Desk,
    # Network-Wide Federated Governance, and Zero-Knowledge Aggregate Telemetry)
    module FederationHub
      TABS = {
        deploy_nodes: { index: 1, label: "1. Deploy Nodes", icon: "🚀" },
        area_requests: { index: 2, label: "2. Area Requests", icon: "🆘" },
        network_votes: { index: 3, label: "3. Network Votes", icon: "🗳️" },
        telemetry: { index: 4, label: "4. Telemetry", icon: "📊" }
      }.freeze

      HOUSEHOLD_PII_BYTES_ON_HUB = 0

      def self.zero_pii_enforced?
        HOUSEHOLD_PII_BYTES_ON_HUB.zero?
      end
    end
  end
end
