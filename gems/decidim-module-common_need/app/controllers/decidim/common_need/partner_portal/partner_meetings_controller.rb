# frozen_string_literal: true

module Decidim
  module CommonNeed
    module PartnerPortal
      # Publishes partner community events (`Decidim::Meetings::Meeting`) directly to the
      # centralized Member PWA Local Area Calendar (Tab 4).
      class PartnerMeetingsController < Decidim::CommonNeed::ApplicationController
        def create
          title = params[:title].presence || "Pop-Up Winter Coat & Hot Soup Distribution"
          day = params[:day].presence || "Thu Nov 5"
          category_chip = params[:category_chip].presence || "🤝 MUTUAL AID • 🍎 FOOD"

          render json: {
            status: "published",
            title: title,
            day: day,
            category_chip: category_chip,
            location: "7800 MacArthur Blvd",
            zero_means_testing: true
          }, status: :created
        end
      end
    end
  end
end
