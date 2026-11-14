# frozen_string_literal: true

Gem::Specification.new do |s|
  s.version = "0.32.4"
  s.authors = ["The Common Need Federated Mutual Aid Collective"]
  s.email = ["solidarity@commonneed.org"]
  s.license = "AGPL-3.0"
  s.homepage = "https://github.com/GenieSullivan26/The-Common-Need-Main"
  s.required_ruby_version = ">= 3.1"

  s.name = "decidim-courier"
  s.summary = "Decidim Volunteer Courier Offline OSRM Routing & Shift Engine"
  s.description = "Mountable Decidim Engine for Role 2 (Decidim::Courier::VolunteerPortal) providing offline-first OSRM routing, turn-by-turn Web Speech navigation, and volunteer timebank shifts."

  s.files = Dir["{app,config,db,lib}/**/*"]
  s.add_dependency "aasm", "~> 5.5"
  s.add_dependency "activerecord-postgis-adapter", "~> 9.0"
  s.add_dependency "decidim-core", "~> 0.32.0"
  s.add_dependency "decidim-meetings", "~> 0.32.0"
end
