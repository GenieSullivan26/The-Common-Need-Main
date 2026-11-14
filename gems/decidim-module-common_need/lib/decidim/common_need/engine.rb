# frozen_string_literal: true

require "rails"
require "decidim/core"
require "active_record/connection_adapters/postgis_adapter"
require "aasm"

module Decidim
  module CommonNeed
    # Mountable Rails Engine for The Common Need 5-Role PWA Suite.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::CommonNeed

      routes do
        root to: "pwa_portal#index"

        # PWA Manifest & Offline Workbox/IndexedDB Service Worker
        get "/manifest.json", to: "pwa_manifest#manifest", as: :pwa_manifest, defaults: { format: :json }
        get "/service-worker.js", to: "pwa_manifest#service_worker", as: :pwa_service_worker, defaults: { format: :js }

        # Role 1: Member PWA (Decidim::CommonNeed::MemberPortal)
        namespace :member_portal, path: "member" do
          get "catalog", to: "catalog#index"
          post "ai_assistant/chat", to: "ai_assistant#chat"
          post "ai_assistant/paperwork", to: "ai_assistant#generate_paperwork"
          resource :care_basket, only: [:show, :update] do
            post :add_item
            patch :adjust_quantity
            patch :update_handoff
            post :checkout
          end
          resources :calendar_events, only: [:index] do
            member do
              post :rsvp
              post :request_event_box
            end
            collection do
              get :export_ics, defaults: { format: :ics }
            end
          end
          resources :governance_ballots, only: [:index] do
            member do
              post :vote
            end
          end
        end

        # Role 2: Volunteer Courier PWA (Decidim::Courier::VolunteerPortal)
        namespace :volunteer_portal, path: "volunteer" do
          resources :routes, only: [:index, :show] do
            member do
              get :offline_bundle, defaults: { format: :json }
            end
            resources :route_stops, only: [] do
              member do
                post :confirm_stop
              end
            end
          end
          resources :shifts, only: [:index] do
            member do
              post :claim_shift
            end
          end
        end

        # Role 3: Partner Non-Profit PWA (Decidim::Services::PartnerPortal)
        namespace :partner_portal, path: "partner" do
          get "dashboard", to: "dashboard#show"
          resources :batches, only: [:index] do
            member do
              post :verify_and_stage_crates
            end
          end
          resources :surplus_items, only: [:index, :create]
          resources :partner_meetings, only: [:create]
          get "accountability_ledger", to: "dashboard#accountability"
        end

        # Role 4: Local Node Admin PWA (Decidim::CommonNeed::LocalNodeAdmin)
        namespace :local_node_admin, path: "local_node" do
          get "analytics", to: "analytics#show"
          resources :partner_applications, only: [:index, :create] do
            member do
              post :approve
              post :hold
            end
          end
          resources :moderations, only: [:index] do
            member do
              post :resolve_flag
            end
          end
          resources :local_ballots, only: [:index] do
            member do
              post :vote
            end
          end
        end

        # Role 5: Central Hub Federation PWA (Decidim::CommonNeed::FederationHub)
        namespace :federation_hub, path: "federation" do
          resources :federated_nodes, only: [:index, :create] do
            collection do
              post :sync_all
            end
          end
          resources :inter_node_requests, only: [:index, :create] do
            member do
              post :approve_and_dispatch
            end
          end
          resources :network_proposals, only: [:index] do
            member do
              post :cast_vote
            end
          end
          get "telemetry", to: "telemetry#show", defaults: { format: :json }
        end
      end

      initializer "decidim_common_need.add_cells_view_paths" do
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::CommonNeed::Engine.root}/app/cells")
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::CommonNeed::Engine.root}/app/views")
      end

      initializer "decidim_common_need.register_verifications" do
        Decidim::Verifications.register_workflow(:non_profit_handler) do |workflow|
          workflow.form = "Decidim::Verifications::NonProfitHandler"
          workflow.expires_in = 1.year
          workflow.renewable = true
        end
      end

      initializer "decidim_common_need.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end
    end
  end
end
