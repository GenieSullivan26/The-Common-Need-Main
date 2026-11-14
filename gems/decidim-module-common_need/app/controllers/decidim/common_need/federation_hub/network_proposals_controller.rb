# frozen_string_literal: true

module Decidim
  module CommonNeed
    module FederationHub
      # Role 5 (Central Hub Federation PWA) Syndicated Network-Wide Governance (`#NET-88`) controller.
      class NetworkProposalsController < Decidim::CommonNeed::ApplicationController
        def index
          render json: {
            proposals: [
              {
                code: "DECIDIM-PROPOSALS • #NET-88",
                badge: "14/14 NODES VOTING",
                title: "Inter-Node Solidarity & Emergency Grain Reserve Protocol",
                support_count: 3842,
                oppose_count: 245,
                support_pct: 94.0
              }
            ]
          }
        end

        def cast_vote
          render json: {
            status: "voted",
            proposal_id: params[:id],
            support_count: 3843,
            oppose_count: 245,
            support_pct: 94.1,
            tally_label: "3,843 Support (94.1%) • 245 Oppose",
            button_label: "✓ Voted Support (3,843)"
          }
        end
      end
    end
  end
end
