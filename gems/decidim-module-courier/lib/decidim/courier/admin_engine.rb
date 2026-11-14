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
