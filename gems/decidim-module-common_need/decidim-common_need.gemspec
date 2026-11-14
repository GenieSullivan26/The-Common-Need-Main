# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)
require "decidim/common_need/version"

Gem::Specification.new do |s|
  s.version = Decidim::CommonNeed.version
  s.authors = ["The Common Need Federated Mutual Aid Collective"]
  s.email = ["solidarity@commonneed.org"]
  s.license = "AGPL-3.0"
  s.homepage = "https://github.com/GenieSullivan26/The-Common-Need-Main"
  s.required_ruby_version = ">= 3.1"

  s.name = "decidim-common_need"
  s.summary = "Decidim Common Need Component Engine & 5-Role Federated Mutual Aid PWA Suite"
  s.description = "A native, mountable Decidim v0.32+ Component Engine and Offline-First 5-Role PWA Suite " \
                  "(Member, Volunteer Courier, Partner Non-Profit, Local Node Admin, Central Hub Federation) " \
                  "with PostGIS spatial queries, OSRM offline navigation, Local Node Ollama AI Paperwork Co-Pilot, " \
                  "and a De-Commodified Community Value & Care Ledger."

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE-AGPLv3.txt", "Rakefile", "README.md"]

  s.add_dependency "aasm", "~> 5.5"
  s.add_dependency "activerecord-postgis-adapter", "~> 9.0"
  s.add_dependency "decidim-accountability", "~> 0.32.0"
  s.add_dependency "decidim-admin", "~> 0.32.0"
  s.add_dependency "decidim-ai", "~> 0.32.0"
  s.add_dependency "decidim-core", "~> 0.32.0"
  s.add_dependency "decidim-meetings", "~> 0.32.0"
  s.add_dependency "decidim-proposals", "~> 0.32.0"
  s.add_dependency "decidim-verifications", "~> 0.32.0"
  s.add_dependency "doorkeeper", "~> 5.7"
  s.add_dependency "rgeo", "~> 3.0"
  s.add_dependency "rgeo-geojson", "~> 2.2"
  s.add_dependency "stimulus-rails", "~> 1.3"
  s.add_dependency "turbo-rails", "~> 2.0"

  s.add_development_dependency "decidim-dev", "~> 0.32.0"
  s.add_development_dependency "rspec-rails", "~> 7.0"
  s.add_development_dependency "rubocop-decidim", "~> 0.32.0"
end
