# frozen_string_literal: true

module Decidim
  module Services
    # Role 3: Partner Non-Profit PWA Portal (Loading Ramp Handoff, Live Surplus Inventory & Calendar Publisher,
    # and Local Node Accountability Ledger)
    module PartnerPortal
      TABS = {
        handoff: { index: 1, label: "1. Handoff", icon: "🚚" },
        stock: { index: 2, label: "2. Stock", icon: "📦" },
        audit: { index: 3, label: "3. Audit", icon: "📊" }
      }.freeze

      VERIFICATION_WORKFLOW = :non_profit_handler

      def self.requires_non_profit_verification?
        true
      end
    end
  end
end
