# frozen_string_literal: true

module Decidim
  module CommonNeed
    module LocalNodeAdmin
      # Manages local node parameter ballots (`LOCAL BALLOT #OAK-09`) on the Local Node PWA.
      class LocalBallotsController < Decidim::CommonNeed::ApplicationController
        def index
          render json: {
            node_code: current_local_node_code,
            ballots: [
              {
                code: "LOCAL BALLOT #OAK-09",
                title: "Expand East Oakland Delivery Radius to 90th Ave",
                quorum_pct: 92,
                voted: true
              }
            ]
          }
        end

        def vote
          render json: {
            status: "voted",
            ballot_id: params[:id],
            badge: "Voted Support ✓"
          }
        end
      end
    end
  end
end
