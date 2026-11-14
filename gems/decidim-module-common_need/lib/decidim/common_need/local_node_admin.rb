# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Role 4: Local Node Admin PWA Portal (Community Analytics, Partner Onboarding & Moderation,
    # Member Requests & Content Moderation, and Local Node Ballots)
    module LocalNodeAdmin
      TABS = {
        analytics: { index: 1, label: "1. Analytics", icon: "📊" },
        partners: { index: 2, label: "2. Partners", icon: "🏢" },
        requests: { index: 3, label: "3. Requests", icon: "🛡️" },
        votes: { index: 4, label: "4. Votes", icon: "🗳️" }
      }.freeze

      def self.node_code
        Decidim::CommonNeed.local_node_code
      end
    end
  end
end
