# frozen_string_literal: true

module Decidim
  module CommonNeed
    module VolunteerPortal
      # Serves Volunteer Courier PWA routes and offline OSRM bundles (`BATCH #OAK-409`).
      class RoutesController < Decidim::CommonNeed::ApplicationController
        def index
          render json: {
            batch_code: Decidim::Courier::VolunteerPortal::DEFAULT_BATCH_CODE,
            loop_title: Decidim::Courier::VolunteerPortal::DEFAULT_LOOP_TITLE,
            offline_ready: Decidim::Courier::VolunteerPortal.offline_ready?
          }
        end

        def show
          render json: offline_bundle_payload
        end

        def offline_bundle
          render json: offline_bundle_payload
        end

        private

        def offline_bundle_payload
          {
            batch_code: "BATCH #OAK-409",
            loop_title: "Deep East Oakland → Fruitvale Loop",
            duration_label: "42 mins • 4.6 mi",
            osrm_endpoint: Decidim::CommonNeed.local_osrm_endpoint,
            polyline: [
              [37.7651, -122.1755],
              [37.8215, -122.2769],
              [37.7685, -122.1960]
            ],
            maneuvers: [
              { counter: "[ ↱ ] LEG 1 OF 3 • STEP 1/4", dist: "5.8 mi (9 min)", text: "Head northwest on MacArthur Blvd and merge onto I-580 W toward West Oakland." },
              { counter: "[ ↖ ] LEG 1 OF 3 • STEP 2/4", dist: "0.6 mi (2 min)", text: "Take Exit 19C toward West St / San Pablo Ave and merge onto 36th St toward Stop #2." },
              { counter: "[ ↰ ] LEG 1 OF 3 • STEP 3/4", dist: "0.4 mi (1 min)", text: "Turn left onto San Pablo Ave toward 31st St." },
              { counter: "[ 🏁 ] LEG 1 OF 3 • STEP 4/4", dist: "0.0 mi (Arrive)", text: "Arrive at Stop #2: West County Mutual Aid Care Hub (3115 San Pablo Ave) on right." }
            ]
          }
        end
      end
    end
  end
end
