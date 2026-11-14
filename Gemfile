# frozen_string_literal: true

source "https://rubygems.org"

ruby ">= 3.1.0"

gem "rails", "~> 7.2.0"
gem "pg", "~> 1.5"
gem "activerecord-postgis-adapter", "~> 9.0"
gem "rgeo", "~> 3.0"
gem "rgeo-geojson", "~> 2.2"
gem "aasm", "~> 5.5"

# Decidim v0.32 Participatory Democracy Stack
gem "decidim", "~> 0.32.0"
gem "decidim-core", "~> 0.32.0"
gem "decidim-admin", "~> 0.32.0"
gem "decidim-meetings", "~> 0.32.0"
gem "decidim-proposals", "~> 0.32.0"
gem "decidim-accountability", "~> 0.32.0"
gem "decidim-verifications", "~> 0.32.0"
gem "decidim-ai", "~> 0.32.0"

# Hotwire & PWA Stack
gem "turbo-rails", "~> 2.0"
gem "stimulus-rails", "~> 1.3"
gem "doorkeeper", "~> 5.7"

# Local Mountable Engines
gem "decidim-common_need", path: "gems/decidim-module-common_need"
gem "decidim-courier", path: "gems/decidim-module-courier"
gem "decidim-services", path: "gems/decidim-module-services"

group :development, :test do
  gem "rspec-rails", "~> 7.0"
  gem "capybara", "~> 3.40"
  gem "factory_bot_rails", "~> 6.4"
  gem "rubocop-decidim", "~> 0.32.0", require: false
end
