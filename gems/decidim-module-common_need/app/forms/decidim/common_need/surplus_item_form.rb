# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Form object for Partner Non-Profit organizations posting live surplus inventory
    # to the local node catalog across the 19 Decidim community taxonomies.
    class SurplusItemForm < Decidim::Form
      mimic :surplus_item

      attribute :hub_id, Integer
      attribute :title, String
      attribute :description, String
      attribute :stock_quantity, Integer, default: 20
      attribute :category_key, String, default: "food"
      attribute :dietary_and_safety_tags, Array[String], default: ["Fresh Surplus", "Local Node #1"]
      attribute :latitude, Float, default: 37.7651
      attribute :longitude, Float, default: -122.1755
      attribute :weight_lbs, Float, default: 25.0

      validates :hub_id, presence: true
      validates :title, presence: true
      validates :stock_quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
      validates :category_key, presence: true, inclusion: { in: Decidim::CommonNeed::COMMUNITY_TAXONOMY_CATEGORIES }
      validates :latitude, presence: true, numericality: { greater_than_or_equal_to: -90.0, less_than_or_equal_to: 90.0 }
      validates :longitude, presence: true, numericality: { greater_than_or_equal_to: -180.0, less_than_or_equal_to: 180.0 }

      def pickup_coordinates
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
