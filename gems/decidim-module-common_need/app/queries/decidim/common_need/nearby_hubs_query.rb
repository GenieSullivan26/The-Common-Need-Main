# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Queries nearby community pantry & mutual-aid hubs using PostGIS `ST_DWithin`
    # and orders them by `ST_Distance` (SRID 4326 geography), with optional
    # 19-category taxonomy and keyword filtering.
    class NearbyHubsQuery < Decidim::Query
      DEFAULT_LATITUDE = 37.7685
      DEFAULT_LONGITUDE = -122.1960
      DEFAULT_RADIUS_METERS = 12_000

      attr_reader :component, :latitude, :longitude, :radius_meters, :category_key, :search_text

      def initialize(
        component: nil,
        latitude: DEFAULT_LATITUDE,
        longitude: DEFAULT_LONGITUDE,
        radius_meters: DEFAULT_RADIUS_METERS,
        category_key: nil,
        search_text: nil
      )
        @component = component
        @latitude = latitude.to_f
        @longitude = longitude.to_f
        @radius_meters = radius_meters.to_i
        @category_key = category_key.to_s.strip
        @search_text = search_text.to_s.strip
      end

      def query
        scope = base_scope
        scope = filter_by_component(scope)
        scope = filter_by_spatial_radius(scope)
        scope = filter_by_category(scope)
        scope = filter_by_search_text(scope)
        order_by_spatial_distance(scope)
      end

      def spatial_sql_clause
        "ST_DWithin(coordinates, ST_SetSRID(ST_MakePoint(#{longitude}, #{latitude}), 4326)::geography, #{radius_meters})"
      end

      def distance_sql_expression
        "ST_Distance(coordinates, ST_SetSRID(ST_MakePoint(#{longitude}, #{latitude}), 4326)::geography)"
      end

      private

      def base_scope
        Decidim::CommonNeed::Hub.all
      end

      def filter_by_component(scope)
        return scope unless component.respond_to?(:id)

        scope.where(decidim_component_id: component.id)
      end

      def filter_by_spatial_radius(scope)
        return scope if radius_meters <= 0

        scope.where(
          "coordinates IS NULL OR ST_DWithin(coordinates, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography, :radius)",
          lng: longitude,
          lat: latitude,
          radius: radius_meters
        )
      end

      def filter_by_category(scope)
        return scope if category_key.blank? || category_key == "all"

        scope.where(":cat = ANY(category_keys)", cat: category_key)
      end

      def filter_by_search_text(scope)
        return scope if search_text.blank?

        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(search_text.downcase)}%"
        scope.where("LOWER(title::text) LIKE :q OR LOWER(COALESCE(address, '')) LIKE :q", q: pattern)
      end

      def order_by_spatial_distance(scope)
        point_sql = ActiveRecord::Base.sanitize_sql_array(
          ["ST_Distance(coordinates, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography) ASC NULLS LAST", longitude, latitude]
        )
        scope.order(Arel.sql(point_sql))
      end
    end
  end
end
