# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Role 1: Member PWA Portal (19-Category Community Catalog, Local AI & Paperwork Co-Pilot,
    # Multi-Hub Care Basket with Low-Data Delivery Banner, Partner Calendar, and 1-Member-1-Vote Governance)
    module MemberPortal
      TABS = {
        browse: { index: 1, label: "1. Browse", icon: "🛍️" },
        ai_helper: { index: 5, label: "2. AI Helper", icon: "🤖" },
        basket: { index: 2, label: "3. Basket", icon: "📦" },
        calendar: { index: 6, label: "4. Calendar", icon: "📅" },
        vote: { index: 4, label: "5. Vote", icon: "🗳️" }
      }.freeze

      PAPERWORK_TEMPLATES = [
        "Social Services: CalFresh / SNAP, Medi-Cal & LIHEAP Packet",
        "Legal Aid: Eviction Defense & Record Expungement Intake",
        "Housing: Emergency Rent Relief & Habitability Packet",
        "Public Sector: Municipal ID & Paratransit Fee Waiver",
        "Veteran Services: VA Disability Claim & DD-214 Support Packet"
      ].freeze

      def self.zero_means_testing?
        true
      end
    end
  end
end
