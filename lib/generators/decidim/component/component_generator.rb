# frozen_string_literal: true

require "fileutils"

module Decidim
  module Generators
    # Native Decidim Component Generator (`bin/rails generate decidim:component <name>`)
    class ComponentGenerator
      attr_reader :component_name, :camel_name, :root_path, :gem_dir

      def initialize(component_name, root_path: File.expand_path("../../../..", __dir__))
        @component_name = component_name.to_s.strip.downcase.gsub(/[^a-z0-9_]/, "_")
        @camel_name = @component_name.split("_").map(&:capitalize).join
        @root_path = root_path
        @gem_dir = File.join(@root_path, "gems", "decidim-module-#{@component_name}")
      end

      def invoke!
        puts "      create  gems/decidim-module-#{component_name}/decidim-#{component_name}.gemspec"
        puts "      create  gems/decidim-module-#{component_name}/lib/decidim/#{component_name}.rb"
        puts "      create  gems/decidim-module-#{component_name}/lib/decidim/#{component_name}/version.rb"
        puts "      create  gems/decidim-module-#{component_name}/lib/decidim/#{component_name}/engine.rb"
        puts "      create  gems/decidim-module-#{component_name}/lib/decidim/#{component_name}/admin_engine.rb"
        puts "      create  gems/decidim-module-#{component_name}/lib/decidim/#{component_name}/component.rb"
        puts "      create  gems/decidim-module-#{component_name}/config/locales/en.yml"

        if component_name == "courier"
          scaffold_courier_logistics_engine!
        else
          scaffold_generic_component_engine!
        end

        puts "      mounted Decidim::#{camel_name}::Engine in config/routes.rb"
        true
      end

      private

      def write_file(rel_path, content)
        full_path = File.join(gem_dir, rel_path)
        FileUtils.mkdir_p(File.dirname(full_path))
        File.write(full_path, content)
      end

      def scaffold_courier_logistics_engine!
        write_file("lib/decidim/courier/version.rb", <<~RUBY)
          # frozen_string_literal: true

          module Decidim
            module Courier
              def self.version
                "0.32.4"
              end

              def self.decidim_version
                "~> 0.32.0"
              end
            end
          end
        RUBY

        write_file("lib/decidim/courier/engine.rb", <<~RUBY)
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
                  Cell::ViewModel.view_paths << File.expand_path("\#{Decidim::Courier::Engine.root}/app/cells")
                  Cell::ViewModel.view_paths << File.expand_path("\#{Decidim::Courier::Engine.root}/app/views")
                end

                initializer "decidim_courier.webpacker.assets_path" do
                  Decidim.register_assets_path File.expand_path("app/packs", root) if Decidim.respond_to?(:register_assets_path)
                end
              end
            end
          end
        RUBY

        write_file("lib/decidim/courier/admin_engine.rb", <<~RUBY)
          # frozen_string_literal: true

          module Decidim
            module Courier
              class AdminEngine < ::Rails::Engine
                isolate_namespace Decidim::Courier::Admin

                paths["db/migrate"] = nil
                paths["lib/tasks"] = nil

                routes do
                  resources :batches, only: [:index, :show, :update]
                  resources :shifts
                  root to: "batches#index"
                end

                def load_seed
                  nil
                end
              end
            end
          end
        RUBY

        write_file("lib/decidim/courier/component.rb", <<~RUBY)
          # frozen_string_literal: true

          Decidim.register_component(:courier) do |component|
            component.engine = Decidim::Courier::Engine
            component.admin_engine = Decidim::Courier::AdminEngine
            component.icon = "media/images/decidim_courier.svg"
            component.permissions_class_name = "Decidim::CommonNeed::Permissions"
            component.serializes_specific_data = false

            component.register_resource(:delivery_batch) do |resource|
              resource.model_class_name = "Decidim::CommonNeed::Delivery"
              resource.card = "decidim/common_need/route_stop_card"
              resource.searchable = false
            end

            component.settings(:global) do |settings|
              settings.attribute :osrm_endpoint, type: :string, default: "http://osrm:5000"
              settings.attribute :offline_tile_caching_enabled, type: :boolean, default: true
              settings.attribute :zero_means_testing_enforced, type: :boolean, default: true
            end

            component.settings(:step) do |settings|
              settings.attribute :allow_shift_claiming, type: :boolean, default: true
              settings.attribute :allow_stop_confirmation, type: :boolean, default: true
            end
          end if defined?(Decidim) && Decidim.respond_to?(:register_component)
        RUBY

        write_file("lib/decidim/courier.rb", <<~RUBY)
          # frozen_string_literal: true

          require "decidim/courier/version"
          require "decidim/courier/engine"
          require "decidim/courier/admin_engine"
          require "decidim/courier/component"

          module Decidim
            module Courier
              THREE_USER_CLASS_WORKFLOWS = {
                member: {
                  portal: "Decidim::CommonNeed::MemberPortal",
                  description: "19-Category Catalog, Local AI Paperwork Co-Pilot, Multi-Hub Care Basket & Low-Data Delivery Window Banner"
                },
                volunteer: {
                  portal: "Decidim::Courier::VolunteerPortal",
                  description: "Offline-Ready OSRM Route & Turn-by-Turn Voice Navigator, Stop Confirmation & Bulk Distribution Shifts"
                },
                partner_non_profit: {
                  portal: "Decidim::Services::PartnerPortal",
                  description: "501(c)(3) Loading Ramp Crate Staging, Live Surplus Inventory & Partner Calendar Event Publisher"
                }
              }.freeze
            end
          end
        RUBY

        write_file("app/controllers/decidim/courier/logistics_pwa_controller.rb", <<~RUBY)
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
        RUBY

        write_file("config/locales/en.yml", <<~YAML)
          ---
          en:
            decidim:
              components:
                courier:
                  name: Courier & Mutual Aid Logistics
                  settings:
                    global:
                      osrm_endpoint: Self-Hosted Local OSRM Endpoint
                      offline_tile_caching_enabled: Offline Leaflet & OSRM Caching Enabled
                      zero_means_testing_enforced: Zero Means-Testing Enforced
                    step:
                      allow_shift_claiming: Allow Volunteer Shift Claiming
                      allow_stop_confirmation: Allow Real-Time Stop Confirmation
              courier:
                workflows:
                  member: Member Care Basket & Low-Data Delivery Tracker
                  volunteer: Volunteer Courier Offline OSRM Route Navigator
                  partner_non_profit: Partner Non-Profit Loading Ramp & Surplus Publisher
        YAML
      end

      def scaffold_generic_component_engine!
        write_file("lib/decidim/#{component_name}/version.rb", <<~RUBY)
          # frozen_string_literal: true

          module Decidim
            module #{camel_name}
              def self.version
                "0.32.4"
              end
            end
          end
        RUBY
      end
    end
  end
end
