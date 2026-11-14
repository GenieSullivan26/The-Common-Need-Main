# frozen_string_literal: true

module Decidim
  module CommonNeed
    module MemberPortal
      # Handles `1 Member = 1 Vote` democratic governance proposals on the Member PWA.
      class GovernanceBallotsController < Decidim::CommonNeed::ApplicationController
        def index
          render json: {
            node_code: current_local_node_code,
            principle: "1 MEMBER = 1 VOTE",
            proposals: [
              {
                code: "DECIDIM-PROPOSALS • #206",
                title: "East Oakland Local Node Routing Standard",
                quorum_pct: 96,
                voted: true
              }
            ]
          }
        end

        def vote
          render json: {
            status: "voted",
            proposal_id: params[:id],
            label: "Voted Support ✓"
          }
        end
      end
    end
  end
end
