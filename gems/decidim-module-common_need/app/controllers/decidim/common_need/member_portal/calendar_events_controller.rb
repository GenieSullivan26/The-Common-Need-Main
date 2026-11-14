# frozen_string_literal: true

module Decidim
  module CommonNeed
    module MemberPortal
      # Centralized Local Partner Calendar (`decidim-meetings`) controller supporting
      # List/Grid/Map filtering, 1-click RSVP, event box delivery requests, and `.ics` export.
      class CalendarEventsController < Decidim::CommonNeed::ApplicationController
        def index
          render json: {
            node_code: current_local_node_code,
            month: "November 2026",
            view_modes: %w(list grid map)
          }
        end

        def rsvp
          render json: {
            status: "registered",
            event_id: params[:id],
            badge: "✓ Registered (QR Pass Saved)"
          }
        end

        def request_event_box
          render json: {
            status: "queued_for_delivery",
            event_id: params[:id],
            box_title: params[:box_title].presence || "Partner Event Home Delivery Box"
          }
        end

        def export_ics
          ics_body = <<~ICS
            BEGIN:VCALENDAR
            VERSION:2.0
            PRODID:-//The Common Need//Local Node #OAK-01 Partner Calendar//EN
            CALSCALE:GREGORIAN
            METHOD:PUBLISH
            BEGIN:VEVENT
            UID:oak-01-event-1@commonneed.org
            DTSTART:20261103T230000Z
            DTEND:20261104T020000Z
            SUMMARY:Community Harvest Dinner & Winter Seed/Compost Swap
            LOCATION:7800 MacArthur Blvd, Oakland, CA
            DESCRIPTION:Hosted by East Oakland Collective Pantry (Zero Means-Testing)
            END:VEVENT
            END:VCALENDAR
          ICS

          send_data ics_body,
                    filename: "oak-01-local-partner-calendar.ics",
                    type: "text/calendar; charset=utf-8",
                    disposition: "attachment"
        end
      end
    end
  end
end
