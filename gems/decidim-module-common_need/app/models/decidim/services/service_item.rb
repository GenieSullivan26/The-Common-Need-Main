# frozen_string_literal: true

module Decidim
  module Services
    # De-commodified community good, care kit, equipment share, or paperwork service across the 19 Decidim categories.
    class ServiceItem < Decidim::CommonNeed::ApplicationRecord
      include Decidim::HasComponent
      include Decidim::Taxonomizable
      include Decidim::Authorable
      include Decidim::Traceable
      include Decidim::Loggable
      include Decidim::Reportable
      include Decidim::Searchable
      include AASM

      self.table_name = "decidim_services_service_items"

      component_manifest_name "common_need"

      rgeo_factory_for_column(:pickup_coordinates, RGeo::Geographic.spherical_factory(srid: 4326))

      belongs_to :hub,
                 class_name: "Decidim::CommonNeed::Hub",
                 foreign_key: :decidim_common_need_hub_id,
                 inverse_of: :service_items

      has_many :care_basket_items,
               class_name: "Decidim::CommonNeed::CareBasketItem",
               foreign_key: :decidim_services_service_item_id,
               dependent: :nullify

      validates :category_key,
                presence: true,
                inclusion: { in: Decidim::CommonNeed::COMMUNITY_TAXONOMY_CATEGORIES }
      validates :title, presence: true
      validates :stock_quantity, numericality: { greater_than_or_equal_to: 0 }

      scope :by_category, lambda { |category|
        if category.present? && category.to_s != "all"
          where(category_key: category.to_s)
        else
          all
        end
      }

      scope :matching_query, lambda { |query|
        if query.present?
          q = "%#{sanitize_sql_like(query.to_s.strip)}%"
          where(
            "title ILIKE :q OR dietary_and_safety_tags ILIKE :q OR yield_summary ILIKE :q OR category_key ILIKE :q",
            q: q
          )
        else
          all
        end
      }

      scope :in_stock, -> { where(state: %w(available low_stock)).where("stock_quantity > 0") }

      aasm column: :state do
        state :available, initial: true
        state :low_stock
        state :depleted

        event :mark_low_stock do
          transitions from: [:available, :depleted], to: :low_stock
        end

        event :deplete_stock do
          transitions from: [:available, :low_stock], to: :depleted
        end

        event :restock do
          transitions from: [:low_stock, :depleted, :available], to: :available
        end
      end

      searchable_fields(
        {
          participatory_space: { component: :participatory_space },
          A: :title,
          B: :dietary_and_safety_tags,
          C: :yield_summary,
          datetime: :created_at
        },
        index_on_create: ->(_item) { true },
        index_on_update: ->(_item) { true }
      )

      def paperwork_mode?
        interaction_mode == "ai_paperwork"
      end

      def stepper_mode?
        interaction_mode == "stepper"
      end

      def latitude
        pickup_coordinates&.y || hub&.latitude
      end

      def longitude
        pickup_coordinates&.x || hub&.longitude
      end
    end
  end
end
