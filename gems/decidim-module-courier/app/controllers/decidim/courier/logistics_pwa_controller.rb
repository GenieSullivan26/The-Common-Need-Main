# frozen_string_literal: true

module Decidim
  module Courier
    class LogisticsPwaController < Decidim::CommonNeed::ApplicationController
      def index
        @workflows = Decidim::Courier::THREE_USER_CLASS_WORKFLOWS
        @active_role = params[:role].presence || "volunteer"
      end

      def manifest
        render json: {
          name: "The Common Need • Courier & Mutual Aid Logistics PWA",
          short_name: "CommonNeed Courier",
          start_url: "/courier",
          display: "standalone",
          background_color: "#120924",
          theme_color: "#120924"
        }
      end
    end
  end
end
