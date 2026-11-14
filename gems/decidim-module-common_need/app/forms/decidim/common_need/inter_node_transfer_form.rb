# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Form object for approving and dispatching an inter-node solidarity surplus transfer
    # (e.g., REQ #401 routing 400 N95 Masks & 20 Staple Grain Boxes from #OAK-01 & #BER-04 to #RCH-03).
    class InterNodeTransferForm < Decidim::Form
      mimic :inter_node_transfer

      attribute :inter_node_request_id, Integer
      attribute :request_code, String, default: "REQ #401"
      attribute :target_node_code, String, default: "#RCH-03"
      attribute :source_node_codes, Array[String], default: ["#OAK-01", "#BER-04"]
      attribute :manifest_summary, String, default: "400 N95 Masks & 20 Staple Grain Boxes"

      validates :inter_node_request_id, presence: true
      validates :source_node_codes, presence: true
      validate :validate_source_nodes_present

      private

      def validate_source_nodes_present
        cleaned = Array(source_node_codes).reject(&:blank?)
        errors.add(:source_node_codes, "must include at least one peered source node") if cleaned.empty?
      end
    end
  end
end
