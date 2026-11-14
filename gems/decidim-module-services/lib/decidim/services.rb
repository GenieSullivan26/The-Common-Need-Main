# frozen_string_literal: true

module Decidim
  module Services
    def self.version
      "0.32.4"
    end

    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Services

      routes do
        root to: "/decidim/common_need/partner_portal/dashboard#show"
      end
    end
  end
end
