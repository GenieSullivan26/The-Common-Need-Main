# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Form object for Partner Non-Profits publishing community events to the
    # centralized Member PWA Local Area Calendar (Tab 4).
    class PartnerEventForm < Decidim::Form
      mimic :partner_event

      ALLOWED_EVENT_DAYS = [
        "Tue Nov 3",
        "Thu Nov 5",
        "Sat Nov 7",
        "Sun Nov 8"
      ].freeze

      attribute :title, String
      attribute :event_day, String, default: "Thu Nov 5"
      attribute :event_time_label, String, default: "5:00 PM"
      attribute :category_tags, String, default: "🤝 MUTUAL AID • 🍎 FOOD"
      attribute :hub_slug, String, default: "east_oakland"
      attribute :location_address, String, default: "7800 MacArthur Blvd"
      attribute :latitude, Float, default: 37.7651
      attribute :longitude, Float, default: -122.1755
      attribute :home_delivery_kit_enabled, Boolean, default: true
      attribute :description, String

      validates :title, presence: true
      validates :event_day, presence: true
      validates :category_tags, presence: true
      validates :hub_slug, presence: true
      validates :location_address, presence: true
      validates :latitude, presence: true, numericality: { greater_than_or_equal_to: -90.0, less_than_or_equal_to: 90.0 }
      validates :longitude, presence: true, numericality: { greater_than_or_equal_to: -180.0, less_than_or_equal_to: 180.0 }

      def event_coordinates
        return nil if latitude.blank? || longitude.blank?

        if defined?(RGeo::Geographic)
          RGeo::Geographic.spherical_factory(srid: 4326).point(longitude.to_f, latitude.to_f)
        else
          "SRID=4326;POINT(#{longitude.to_f} #{latitude.to_f})"
        end
      end
    end
  end
end
