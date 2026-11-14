# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Represents an inter-node solidarity surplus or support request between federated local servers.
    class InterNodeRequest < Decidim::CommonNeed::ApplicationRecord
      include Decidim::HasComponent
      include Decidim::Traceable
      include Decidim::Loggable
      include AASM

      self.table_name = "decidim_common_need_inter_node_requests"

      component_manifest_name "common_need"

      validates :request_code, presence: true, uniqueness: true
      validates :requesting_node_code, presence: true
      validates :requesting_node_name, presence: true
      validates :need_summary, presence: true

      aasm column: :state do
        state :open, initial: true
        state :dispatched
        state :fulfilled

        event :dispatch_transfer do
          transitions from: [:open, :dispatched], to: :dispatched
          after do
            self.dispatched_at ||= Time.current
            save! if persisted?
          end
        end

        event :fulfill_transfer do
          transitions from: [:open, :dispatched, :fulfilled], to: :fulfilled
          after do
            self.dispatched_at ||= Time.current
            save! if persisted?
          end
        end
      end
    end
  end
end
