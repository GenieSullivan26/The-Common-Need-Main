# frozen_string_literal: true

Gem::Specification.new do |s|
  s.version = "0.32.4"
  s.authors = ["The Common Need Federated Mutual Aid Collective"]
  s.email = ["solidarity@commonneed.org"]
  s.license = "AGPL-3.0"
  s.homepage = "https://github.com/GenieSullivan26/The-Common-Need-Main"
  s.required_ruby_version = ">= 3.1"

  s.name = "decidim-services"
  s.summary = "Decidim Partner Non-Profit Surplus Inventory & Accountability Engine"
  s.description = "Mountable Decidim Engine for Role 3 (Decidim::Services::PartnerPortal) providing 501(c)(3) loading ramp batch handoff, live surplus inventory, and Decidim::Accountability auditing."

  s.files = Dir["{app,config,db,lib}/**/*"]
  s.add_dependency "aasm", "~> 5.5"
  s.add_dependency "activerecord-postgis-adapter", "~> 9.0"
  s.add_dependency "decidim-accountability", "~> 0.32.0"
  s.add_dependency "decidim-core", "~> 0.32.0"
  s.add_dependency "decidim-meetings", "~> 0.32.0"
  s.add_dependency "decidim-verifications", "~> 0.32.0"
end
