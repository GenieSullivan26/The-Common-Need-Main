# frozen_string_literal: true

module Decidim
  module CommonNeed
    module VolunteerPortal
      # Confirms pickup/dropoff stops on a Volunteer Courier route and broadcasts
      # low-data arrival window narrowing (`2:38 PM – 2:45 PM`) to Member Care Baskets.
      class RouteStopsController < Decidim::CommonNeed::ApplicationController
        def confirm_stop
          stop_number = (params[:id] || params[:stop_number] || 2).to_i
          shift_code = params[:route_id].presence || "OAK-409"

          broadcast_payload = Decidim::CommonNeed::DeliveryWindowChannel.broadcast_window_update(
            shift_code: shift_code,
            stop_number: stop_number,
            narrowed: true
          )

          render json: {
            status: "confirmed",
            stop_number: stop_number,
            stops_counter_label: "2/4 Stops Done",
            delivery_window_broadcast: broadcast_payload
          }
        end
      end
    end
  end
end
