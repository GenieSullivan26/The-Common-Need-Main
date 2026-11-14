# frozen_string_literal: true

require_relative "boot"

$LOAD_PATH.unshift File.expand_path("../gems/decidim-module-common_need/lib", __dir__)
$LOAD_PATH.unshift File.expand_path("../gems/decidim-module-courier/lib", __dir__)
$LOAD_PATH.unshift File.expand_path("../gems/decidim-module-services/lib", __dir__)

module TheCommonNeedDecidimApp
  # Standard Decidim v0.32 Host Application mounting decidim-common_need,
  # decidim-courier, and decidim-services.
  class Application
    def self.root
      Pathname.new(File.expand_path("..", __dir__))
    end

    def self.config
      @config ||= {
        time_zone: "Pacific Time (US & Canada)",
        i18n_default_locale: :en,
        i18n_available_locales: [:en, :es],
        active_job_queue_adapter: :sidekiq,
        active_storage_service: :local_encrypted_vault,
        force_ssl: ENV.fetch("RAILS_FORCE_SSL", "false") == "true"
      }
    end
  end
end
