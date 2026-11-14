# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Represents a chronological pickup or dropoff stop along a Volunteer Courier's multi-hub batch route.
    class RouteStop < Decidim::CommonNeed::ApplicationRecord
      include Decidim::Traceable
      include Decidim::Loggable
      include AASM

      self.table_name = "decidim_common_need_route_stops"

      rgeo_factory_for_column(:coordinates, RGeo::Geographic.spherical_factory(srid: 4326))

      belongs_to :delivery,
                 class_name: "Decidim::CommonNeed::Delivery",
                 foreign_key: :decidim_common_need_delivery_id,
                 inverse_of: :route_stops

      belongs_to :hub,
                 class_name: "Decidim::CommonNeed::Hub",
                 foreign_key: :decidim_common_need_hub_id,
                 optional: true

      validates :stop_number, presence: true, numericality: { greater_than_or_equal_to: 1 }
      validates :stop_type, inclusion: { in: %w(pickup dropoff) }
      validates :title, presence: true

      aasm column: :state do
        state :pending, initial: true
        state :confirmed
        state :completed

        event :confirm do
          transitions from: [:pending, :confirmed], to: :confirmed
          after do
            self.confirmed_at ||= Time.current
            save! if persisted?
            delivery&.narrow_window_after_stop_2! if stop_number == 2
          end
        end

        event :complete do
          transitions from: [:pending, :confirmed, :completed], to: :completed
          after do
            self.confirmed_at ||= Time.current
            save! if persisted?
          end
        end
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
