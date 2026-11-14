# frozen_string_literal: true

module Decidim
  module CommonNeed
    module MemberPortal
      # Serves the 19-category community goods & services catalog for Role 1 (Member PWA).
      class CatalogController < Decidim::CommonNeed::ApplicationController
        def index
          @active_category = params[:category].presence || "all"
          @search_query = params[:q].to_s.strip
          render json: {
            node_code: current_local_node_code,
            zero_means_testing: Decidim::CommonNeed::MemberPortal.zero_means_testing?,
            active_category: @active_category,
            categories: Decidim::CommonNeed::COMMUNITY_TAXONOMY_CATEGORIES
          }
        end
      end
    end
  end
end
