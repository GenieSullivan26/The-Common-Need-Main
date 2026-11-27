# frozen_string_literal: true

module Decidim
  module CommonNeed
    module PartnerPortal
      # Serves the Partner PWA Community Organizing Hub endpoints:
      # launch & governance guides, coalition campaign logistics, and popular education cohorts.
      class OrganizingHubController < Decidim::CommonNeed::ApplicationController
        def show
          service = Decidim::CommonNeed::CommunityOrganizingService.new(node_code: current_local_node_code)
          render json: service.overview_bundle
        end

        def create_cohort
          service = Decidim::CommonNeed::CommunityOrganizingService.new(node_code: current_local_node_code)
          payload = service.schedule_popular_ed_cohort(
            title: params[:title],
            session_type: params[:session_type] || "Study Circle",
            day: params[:day] || "Sat Nov 7",
            location: params[:location] || "7800 MacArthur Blvd",
            sync_to_member_calendar: params[:sync_to_member_calendar] != false
          )
          render json: payload, status: :created
        end
      end
    end
  end
end
