# frozen_string_literal: true

module Decidim
  module Services
    # Role 3: Partner Non-Profit PWA Portal (Sleek Minimal Gemini-Inspired UI with
    # Top-Left Navigation Dropdown, Top-Right Profile/Sign-Out, Loading Ramp Handoff,
    # Live Surplus & Stock, Dedicated Calendar Publisher, Community Organizing Hub,
    # and Local Node Accountability Ledger)
    module PartnerPortal
      TABS = {
        handoff: { index: 1, label: "Handoff", icon: "🚚" },
        stock: { index: 2, label: "Surplus & Stock", icon: "📦" },
        calendar_publisher: { index: 4, label: "Calendar Publisher", icon: "📅" },
        organizing_hub: { index: 5, label: "Organizing Hub", icon: "✊" },
        audit: { index: 3, label: "Accountability", icon: "📊" }
      }.freeze

      ORGANIZING_PILLARS = {
        guides: "Launch & Governance Guides",
        coalition: "Coalition & Campaign Logistics",
        education: "Class Formation & Popular Education"
      }.freeze

      CURRICULUM_TRACKS = [
        "Mutual Aid vs. Charity & Political Economy of the Neighborhood",
        "Tenant Unions, Land Trusts & Collective Bargaining",
        "Worker Co-ops, Workplace Organizing & Solidarity Economics",
        "Participatory Democracy, Abolitionist Care & Community Safety"
      ].freeze

      VERIFICATION_WORKFLOW = :non_profit_handler

      def self.requires_non_profit_verification?
        true
      end
    end
  end
end
