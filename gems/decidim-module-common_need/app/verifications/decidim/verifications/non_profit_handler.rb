# frozen_string_literal: true

module Decidim
  module Verifications
    # Custom Decidim AuthorizationHandler for verifying 501(c)(3) / mutual-aid collective
    # Partner organizations on the local node (Role 3: Partner Non-Profit PWA).
    class NonProfitHandler < Decidim::AuthorizationHandler
      EIN_FORMAT_REGEX = /\A\d{2}-\d{7}\z/

      attribute :ein_number, String
      attribute :organization_name, String
      attribute :hub_address, String
      attribute :collective_charter_accepted, Boolean, default: false

      validates :ein_number, presence: true, format: { with: EIN_FORMAT_REGEX }
      validates :organization_name, presence: true
      validates :collective_charter_accepted, acceptance: true

      def unique_id
        return nil if ein_number.blank?

        "non_profit_ein_#{ein_number.strip}"
      end

      def metadata
        super.merge(
          ein_number: ein_number,
          organization_name: organization_name,
          hub_address: hub_address,
          collective_charter_accepted: collective_charter_accepted,
          node_code: Decidim::CommonNeed.local_node_code
        )
      end
    end
  end
end
