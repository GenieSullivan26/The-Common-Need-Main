# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Represents a verified neighborhood community pantry, clinic, resource hub, or worker center.
    class Hub < Decidim::CommonNeed::ApplicationRecord
      include Decidim::HasComponent
      include Decidim::Taxonomizable
      include Decidim::Authorable
      include Decidim::Coauthorable
      include Decidim::Traceable
      include Decidim::Loggable
      include Decidim::Reportable
      include Decidim::Searchable
      include AASM

      self.table_name = "decidim_common_need_hubs"

      component_manifest_name "common_need"

      rgeo_factory_for_column(:coordinates, RGeo::Geographic.spherical_factory(srid: 4326))

      has_many :service_items,
               class_name: "Decidim::Services::ServiceItem",
               foreign_key: :decidim_common_need_hub_id,
               dependent: :destroy,
               inverse_of: :hub

      has_many :route_stops,
               class_name: "Decidim::CommonNeed::RouteStop",
               foreign_key: :decidim_common_need_hub_id,
               dependent: :nullify

      validates :slug, presence: true, uniqueness: { scope: :decidim_component_id }
      validates :title, presence: true
      validates :member_audit_score, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 5.0 }

      scope :verified_hubs, -> { where(verification_status: "verified") }
      scope :pending_moderation, -> { where(verification_status: %w(pending on_hold)) }
      scope :with_category, ->(cat_key) { where("? = ANY(category_keys)", cat_key.to_s) }
      scope :within_radius_meters, lambda { |lat, lng, radius_meters = 12_000|
        where(
          "ST_DWithin(coordinates, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?)",
          lng.to_f,
          lat.to_f,
          radius_meters.to_i
        )
      }

      aasm column: :verification_status do
        state :pending
        state :verified, initial: true
        state :on_hold

        event :verify_partner do
          transitions from: [:pending, :on_hold, :verified], to: :verified
        end

        event :hold_partner do
          transitions from: [:pending, :verified, :on_hold], to: :on_hold
        end
      end

      searchable_fields(
        {
          participatory_space: { component: :participatory_space },
          A: :title,
          B: :subtitle,
          C: :address,
          datetime: :created_at
        },
        index_on_create: ->(hub) { hub.verified? },
        index_on_update: ->(hub) { hub.verified? }
      )

      def title_text(locale = :en)
        return title if title.is_a?(String)
        return "" unless title.is_a?(Hash)

        title[locale.to_s] || title[locale.to_sym] || title["en"] || title[:en] || title.values.first.to_s
      end

      def subtitle_text(locale = :en)
        return subtitle if subtitle.is_a?(String)
        return "" unless subtitle.is_a?(Hash)

        subtitle[locale.to_s] || subtitle[locale.to_sym] || subtitle["en"] || subtitle[:en] || subtitle.values.first.to_s
      end

      def latitude
        coordinates&.y
      end

      def longitude
        coordinates&.x
      end
    end
  end
end
