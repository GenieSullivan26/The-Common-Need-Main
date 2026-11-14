# frozen_string_literal: true

require "rails"
require "decidim/core"

module Decidim
  module Courier
    # Mountable Decidim Component Engine for Logistics & Three User Class PWA Integrations:
    # 1. Member Care Basket & Low-Data Delivery Window Tracker
    # 2. Volunteer Courier Offline OSRM Route & Turn-by-Turn Navigator
    # 3. Partner Non-Profit Loading Ramp Handoff & Surplus Stock Publisher
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Courier

      routes do
        root to: "logistics_pwa#index"
        get "/manifest.json", to: "logistics_pwa#manifest", defaults: { format: :json }
        get "/service-worker.js", to: "logistics_pwa#service_worker", defaults: { format: :js }

        resources :batches, only: [:index, :show] do
          member do
            get :offline_osrm_bundle, defaults: { format: :json }
            post :verify_ramp_crates
          end
          resources :stops, only: [] do
            member do
              post :confirm
            end
          end
        end

        resources :shifts, only: [:index] do
          member do
            post :claim
          end
        end
      end

      initializer "decidim_courier.add_cells_view_paths" do
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::Courier::Engine.root}/app/cells")
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::Courier::Engine.root}/app/views")
      end

      initializer "decidim_courier.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root) if Decidim.respond_to?(:register_assets_path)
      end
    end
  end
end
