# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Filters `Decidim::Services::ServiceItem` offerings across all 19 Decidim
    # community taxonomy categories and keyword search terms.
    class CatalogItemsQuery < Decidim::Query
      TAXONOMY_CATEGORIES = Decidim::CommonNeed::COMMUNITY_TAXONOMY_CATEGORIES

      attr_reader :component, :category_key, :search_text, :hub_id

      def initialize(component: nil, category_key: "all", search_text: nil, hub_id: nil)
        @component = component
        @category_key = category_key.to_s.strip.presence || "all"
        @search_text = search_text.to_s.strip
        @hub_id = hub_id
      end

      def query
        scope = Decidim::Services::ServiceItem.all
        scope = scope.where(decidim_component_id: component.id) if component.respond_to?(:id)
        scope = scope.where(decidim_common_need_hub_id: hub_id) if hub_id.present?
        scope = filter_by_taxonomy(scope)
        filter_by_search(scope)
      end

      def valid_taxonomy_category?
        category_key == "all" || TAXONOMY_CATEGORIES.include?(category_key)
      end

      private

      def filter_by_taxonomy(scope)
        return scope if category_key == "all"
        return scope.none unless TAXONOMY_CATEGORIES.include?(category_key)

        scope.where(category_key: category_key)
      end

      def filter_by_search(scope)
        return scope if search_text.blank?

        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(search_text.downcase)}%"
        scope.where(
          "LOWER(title) LIKE :q OR LOWER(COALESCE(dietary_and_safety_tags, '')) LIKE :q OR LOWER(category_key) LIKE :q",
          q: pattern
        )
      end
    end
  end
end
