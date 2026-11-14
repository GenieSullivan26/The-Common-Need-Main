# frozen_string_literal: true

# Decidim Host Application Routes
Rails.application.routes.draw do
  mount Decidim::Core::Engine => "/"
  mount Decidim::CommonNeed::Engine => "/common_need", as: :decidim_common_need
  mount Decidim::Courier::Engine => "/courier", as: :decidim_courier
  mount Decidim::Services::Engine => "/services", as: :decidim_services

  # Root PWA entrypoint
  root to: "decidim/common_need/pwa_portal#index"
end if defined?(Rails) && Rails.respond_to?(:application) && Rails.application
