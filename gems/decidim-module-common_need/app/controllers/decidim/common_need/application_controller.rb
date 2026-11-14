# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Base controller for The Common Need 5-Role Offline-First PWA Suite.
    class ApplicationController < Decidim::Components::BaseController
      helper Decidim::CommonNeed::Engine.routes.url_helpers if defined?(Decidim::CommonNeed::Engine)

      private

      def current_local_node_code
        Decidim::CommonNeed.local_node_code
      end
      helper_method :current_local_node_code
    end
  end
end
