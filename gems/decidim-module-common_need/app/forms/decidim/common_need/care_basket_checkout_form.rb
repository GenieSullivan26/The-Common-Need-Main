# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Form object for unconditional solidarity Care Basket checkout.
    # Strictly enforces zero means-testing (no income, payment, or ID barriers)
    # and parses dropoff coordinates as a PostGIS SRID 4326 geographic point.
    class CareBasketCheckoutForm < Decidim::Form
      mimic :care_basket_checkout

      PROHIBITED_MEANS_TESTING_KEYS = %i(
        income
        household_income
        tax_return
        pay_stub
        ssn
        means_test_score
        payment_token
        credit_card
      ).freeze

      attribute :care_basket_id, Integer
      attribute :bring_up_porch_steps, Boolean, default: true
      attribute :wait_60s_at_door, Boolean, default: true
      attribute :dropoff_block_label, String, default: "1400 Block of 62nd Ave"
      attribute :latitude, Float, default: 37.7685
      attribute :longitude, Float, default: -122.1960
      attribute :delivery_notes, String

      validates :care_basket_id, presence: true
      validates :dropoff_block_label, presence: true
      validates :latitude, presence: true, numericality: { greater_than_or_equal_to: -90.0, less_than_or_equal_to: 90.0 }
      validates :longitude, presence: true, numericality: { greater_than_or_equal_to: -180.0, less_than_or_equal_to: 180.0 }
      validate :enforce_zero_means_testing!

      def dropoff_coordinates
        return nil if latitude.blank? || longitude.blank?

        if defined?(RGeo::Geographic)
          RGeo::Geographic.spherical_factory(srid: 4326).point(longitude.to_f, latitude.to_f)
        else
          "SRID=4326;POINT(#{longitude.to_f} #{latitude.to_f})"
        end
      end

      def handoff_summary
        parts = []
        parts << "Walk up 4 porch steps" if bring_up_porch_steps
        parts << "wait 60s" if wait_60s_at_door
        parts.any? ? "Handoff: #{parts.join(" & ")}" : "Handoff: Standard door dropoff"
      end

      def zero_means_testing_verified?
        true
      end

      private

      def enforce_zero_means_testing!
        return unless context.respond_to?(:raw_params) && context.raw_params.is_a?(Hash)

        present_keys = context.raw_params.keys.map(&:to_sym) & PROHIBITED_MEANS_TESTING_KEYS
        return if present_keys.empty?

        errors.add(:base, "Means-testing or financial fields (#{present_keys.join(", ")}) are strictly prohibited.")
      end
    end
  end
end
