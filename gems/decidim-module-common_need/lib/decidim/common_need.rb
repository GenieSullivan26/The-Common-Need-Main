# frozen_string_literal: true

require "decidim/common_need/version"
require "decidim/common_need/engine"
require "decidim/common_need/admin_engine"
require "decidim/common_need/component"

module Decidim
  # Decidim::CommonNeed is the primary mountable engine for "The Common Need"
  # Federated Mutual Aid Network & 5-Role Offline-First PWA Suite.
  module CommonNeed
    autoload :MemberPortal, "decidim/common_need/member_portal"
    autoload :LocalNodeAdmin, "decidim/common_need/local_node_admin"
    autoload :FederationHub, "decidim/common_need/federation_hub"

    COMMUNITY_TAXONOMY_CATEGORIES = %w(
      food
      mutual_aid
      co_ops
      garden
      pets
      health
      medical
      mental_health
      public_safety
      legal_aid
      housing
      social_services
      public_sector
      veteran_services
      employment
      education
      youth_services
      arts
      recreation
    ).freeze

    # Strictly local-only Ollama endpoint on Node #OAK-01 (Zero External Cloud API)
    mattr_accessor :local_ollama_endpoint, default: ENV.fetch("LOCAL_OLLAMA_URL", "http://127.0.0.1:11434/api/generate")
    mattr_accessor :local_ollama_model, default: ENV.fetch("LOCAL_OLLAMA_MODEL", "llama3:local-oak-01")
    mattr_accessor :local_osrm_endpoint, default: ENV.fetch("LOCAL_OSRM_URL", "http://127.0.0.1:5000")
    mattr_accessor :local_node_code, default: ENV.fetch("LOCAL_NODE_CODE", "#OAK-01")
    mattr_accessor :default_srid, default: 4326
  end

  # Companion namespace for Role 2: Volunteer Courier PWA (Decidim::Courier::VolunteerPortal)
  module Courier
    autoload :VolunteerPortal, "decidim/courier/volunteer_portal"
  end

  # Companion namespace for Role 3: Partner Non-Profit PWA (Decidim::Services::PartnerPortal)
  module Services
    autoload :PartnerPortal, "decidim/services/partner_portal"
    autoload :ServiceItem, "decidim/services/service_item"
  end
end
