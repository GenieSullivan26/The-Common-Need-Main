# frozen_string_literal: true

module Decidim
  module CommonNeed
    module FederationHub
      # Zero-Knowledge Federated Telemetry controller (`0 Bytes` of household PII on Central Hub).
      class TelemetryController < Decidim::CommonNeed::ApplicationController
        def show
          render json: {
            households_served: 4280,
            households_served_label: "4,280 Homes",
            shift_fill_rate_pct: 95.4,
            shift_fill_rate_label: "95.4% Filled",
            surplus_rescued_lbs: 24_680,
            surplus_rescued_label: "24,680 lbs",
            household_pii_bytes_on_hub: Decidim::CommonNeed::FederationHub::HOUSEHOLD_PII_BYTES_ON_HUB,
            household_pii_label: "0 Bytes",
            zero_pii_enforced: Decidim::CommonNeed::FederationHub.zero_pii_enforced?
          }
        end
      end
    end
  end
end
