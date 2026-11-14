# frozen_string_literal: true

module Decidim
  module Courier
    # Role 2: Volunteer PWA Portal (Offline-Ready OSRM Route & Stop Execution + Community Bulk Distribution Shifts)
    module VolunteerPortal
      TABS = {
        route: { index: 1, label: "1. Route", icon: "🗺️" },
        shifts: { index: 2, label: "2. Shifts", icon: "📅" }
      }.freeze

      DEFAULT_BATCH_CODE = "BATCH #OAK-409"
      DEFAULT_LOOP_TITLE = "Deep East Oakland → Fruitvale Loop"

      def self.offline_ready?
        true
      end
    end
  end
end
