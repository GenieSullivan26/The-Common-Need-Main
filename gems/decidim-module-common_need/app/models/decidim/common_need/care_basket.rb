# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Multi-Hub Member Care Basket enforcing Zero-Means-Testing and tracking Community Value & Care Ledger metrics.
    class CareBasket < Decidim::CommonNeed::ApplicationRecord
      include Decidim::HasComponent
      include Decidim::Traceable
      include Decidim::Loggable
      include AASM

      self.table_name = "decidim_common_need_care_baskets"

      component_manifest_name "common_need"

      FORBIDDEN_COMMERCIAL_FIELDS = %w(
        price
        price_cents
        total_price
        total_price_cents
        stripe_payment_intent_id
        income_verification_status
        means_test_score
      ).freeze

      belongs_to :user,
                 class_name: "Decidim::User",
                 foreign_key: :decidim_user_id,
                 optional: true

      has_many :care_basket_items,
               class_name: "Decidim::CommonNeed::CareBasketItem",
               foreign_key: :decidim_common_need_care_basket_id,
               dependent: :destroy,
               inverse_of: :care_basket

      alias_method :items, :care_basket_items

      has_one :delivery,
              class_name: "Decidim::CommonNeed::Delivery",
              foreign_key: :decidim_common_need_care_basket_id,
              dependent: :nullify

      validates :access_principle, inclusion: { in: ["UNCONDITIONAL SOLIDARITY"] }
      validate :enforce_zero_means_testing!

      aasm column: :state do
        state :open, initial: true
        state :dispatched
        state :fulfilled

        event :dispatch_courier do
          transitions from: [:open, :dispatched], to: :dispatched
        end

        event :mark_fulfilled do
          transitions from: [:dispatched, :fulfilled], to: :fulfilled
        end
      end

      def recalculate_ledger!
        active_items = care_basket_items.to_a
        self.total_meals = active_items.sum { |item| item.meals_count.to_i * item.quantity.to_i }
        self.total_protective_items = active_items.sum { |item| item.protective_gear_count.to_i * item.quantity.to_i }
        self.total_weight_lbs = active_items.sum { |item| item.weight_lbs.to_d * item.quantity.to_i }
        save! if persisted?
        self
      end

      def handoff_summary
        parts = []
        parts << "Walk up 4 porch steps" if bring_up_porch_steps?
        parts << "wait 60s" if wait_60s_at_door?
        parts.any? ? "Handoff: #{parts.join(' & ')}" : "Handoff: Standard door dropoff"
      end

      def total_shares_count
        care_basket_items.sum(:quantity)
      end

      def ledger_summary_load
        "#{total_meals} Meals + #{total_protective_items} N95s (#{total_weight_lbs.to_i} lbs)"
      end

      private

      def enforce_zero_means_testing!
        forbidden_present = self.class.column_names & FORBIDDEN_COMMERCIAL_FIELDS
        return if forbidden_present.empty?

        errors.add(:base, "Zero-Means-Testing violation: commercial or pricing fields (#{forbidden_present.join(', ')}) are strictly prohibited")
      end
    end
  end
end
