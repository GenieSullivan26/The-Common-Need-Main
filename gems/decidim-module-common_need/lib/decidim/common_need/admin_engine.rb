# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Decidim Admin Engine for Local Node & Component Administration
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::CommonNeed::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        resources :hubs
        resources :service_items
        resources :deliveries, only: [:index, :show, :update]
        resources :federated_nodes, only: [:index, :create, :update]
        resources :inter_node_requests, only: [:index, :update]
        root to: "hubs#index"
      end

      def load_seed
        nil
      end
    end
  end
end
