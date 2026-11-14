# frozen_string_literal: true

require_dependency "decidim/services/service_item"

module Decidim
  module CommonNeed
    # Alias subclass within Decidim::CommonNeed namespace for seamless component resource resolution.
    class ServiceItem < Decidim::Services::ServiceItem
    end
  end
end
