# frozen_string_literal: true

require "decidim/courier/version"
require "decidim/courier/engine"
require "decidim/courier/admin_engine"
require "decidim/courier/component"

module Decidim
  module Courier
    THREE_USER_CLASS_WORKFLOWS = {
      member: {
        portal: "Decidim::CommonNeed::MemberPortal",
        description: "19-Category Catalog, Local AI Paperwork Co-Pilot, Multi-Hub Care Basket & Low-Data Delivery Window Banner"
      },
      volunteer: {
        portal: "Decidim::Courier::VolunteerPortal",
        description: "Offline-Ready OSRM Route & Turn-by-Turn Voice Navigator, Stop Confirmation & Bulk Distribution Shifts"
      },
      partner_non_profit: {
        portal: "Decidim::Services::PartnerPortal",
        description: "501(c)(3) Loading Ramp Crate Staging, Live Surplus Inventory & Partner Calendar Event Publisher"
      }
    }.freeze
  end
end
