# frozen_string_literal: true

require "rgeo"

module Decidim
  module CommonNeed
    # Abstract base model for The Common Need engine with PostGIS SRID 4326 WGS84 helpers.
    class ApplicationRecord < (defined?(Decidim::ApplicationRecord) ? Decidim::ApplicationRecord : ActiveRecord::Base)
      self.abstract_class = true

      WGS84_FACTORY = RGeo::Geographic.spherical_factory(srid: 4326)

      def self.rgeo_factory_for_column(column_name, factory = WGS84_FACTORY)
        super if defined?(super)
      rescue NoMethodError
        @rgeo_column_factories ||= {}
        @rgeo_column_factories[column_name.to_sym] = factory
      end

      rgeo_factory_for_column(:coordinates, RGeo::Geographic.spherical_factory(srid: 4326))

      def self.point_from_lat_lng(lat, lng)
        return nil if lat.nil? || lng.nil?

        WGS84_FACTORY.point(lng.to_f, lat.to_f)
      end

      def point_from_lat_lng(lat, lng)
        self.class.point_from_lat_lng(lat, lng)
      end
    end
  end
end
