# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Line item within a Member's Multi-Hub Care Basket.
    class CareBasketItem < Decidim::CommonNeed::ApplicationRecord
      include Decidim::Traceable
      include Decidim::Loggable

      self.table_name = "decidim_common_need_care_basket_items"

      belongs_to :care_basket,
                 class_name: "Decidim::CommonNeed::CareBasket",
                 foreign_key: :decidim_common_need_care_basket_id,
                 inverse_of: :care_basket_items

      belongs_to :service_item,
                 class_name: "Decidim::Services::ServiceItem",
                 foreign_key: :decidim_services_service_item_id,
                 optional: true

      validates :item_name, presence: true
      validates :quantity, numericality: { greater_than_or_equal_to: 1 }

      after_save :sync_basket_ledger!
      after_destroy :sync_basket_ledger!

      private

      def sync_basket_ledger!
        care_basket&.recalculate_ledger!
      end
    end
  end
end
