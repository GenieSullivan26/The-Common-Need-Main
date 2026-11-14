# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Decidim::CommonNeed Services" do
  describe Decidim::CommonNeed::OsrmRoutingService do
    let(:service) { Decidim::CommonNeed::OsrmRoutingService.new }

    it "computes a multi-stop route polyline with 4 turn-by-turn maneuver steps and offline fallback" do
      route = service.compute_route

      expect(route[:polyline]).to eq("oak01_east_oakland_west_county_62nd_ave_loop_v1")
      expect(route[:total_duration_minutes]).to eq(42)
      expect(route[:total_distance_miles]).to eq(4.6)
      expect(route[:maneuvers].size).to eq(4)
      expect(route[:maneuvers].first[:counter]).to eq("[ ↱ ] LEG 1 OF 3 • STEP 1/4")
      expect(route[:maneuvers].last[:text]).to include("Arrive at Stop #2: West County Mutual Aid Care Hub")
    end

    it "narrows Stop #3's arrival window from 2:35–2:50 PM to 2:38–2:45 PM when Stop #2 is confirmed" do
      recalc = service.recalculate_after_stop_confirmation(stop_number: 2)

      expect(recalc[:previous_window]).to eq("2:35–2:50 PM")
      expect(recalc[:narrowed_window]).to eq("2:38–2:45 PM")
      expect(recalc[:window_headline]).to eq("Window: 2:38 PM – 2:45 PM (You Are Next!)")
      expect(recalc[:milestone_step]).to eq(3)
      expect(recalc[:stops_completed_label]).to eq("2/4 Stops Done")
    end

    it "builds an offline OSRM bundle payload for Workbox/IndexedDB caching" do
      bundle = service.offline_bundle_payload
      expect(bundle[:batch_code]).to eq("BATCH #OAK-409")
      expect(bundle[:offline_ready]).to be_truthy
      expect(bundle[:maneuvers].size).to eq(4)
    end
  end

  describe Decidim::CommonNeed::LocalAiPaperworkService do
    let(:service) { Decidim::CommonNeed::LocalAiPaperworkService.new }

    it "permits local Ollama endpoint (127.0.0.1:11434) and raises SecurityError on any external cloud endpoint" do
      expect(service.validate_local_endpoint!).to be_truthy

      expect do
        Decidim::CommonNeed::LocalAiPaperworkService.new(endpoint: "https://api.openai.com/v1/chat/completions")
      end.to raise_error(SecurityError, /External cloud AI endpoints .* are strictly prohibited/)
    end

    it "matches prompts across all 4 multi-category solidarity bundles covering the 19 community categories" do
      vet_match = service.match_community_needs("Need Veteran VA claim DD-214 and CalFresh SNAP")
      expect(vet_match[:matched_categories]).to include("social_services", "veteran_services")
      expect(vet_match[:recommended_bundle_title]).to eq("Veteran & Social Services Care Packet")

      legal_match = service.match_community_needs("Facing eviction and need rent relief and municipal ID")
      expect(legal_match[:matched_categories]).to include("legal_aid", "housing", "public_sector")

      health_match = service.match_community_needs("Need bilingual trauma counseling, mobility walker, and youth art kit")
      expect(health_match[:matched_categories]).to include("mental_health", "medical", "youth_services", "arts")

      food_match = service.match_community_needs("Looking for collard greens, garden seeds, pet kibble, and co-op bread")
      expect(food_match[:matched_categories]).to include("food", "garden", "pets", "co_ops", "mutual_aid")
    end

    it "generates an AES-256-GCM ephemeral encrypted PDF packet with 0 external bytes sent" do
      result = service.process_guided_paperwork(
        {
          template_name: "Social Services: CalFresh / SNAP, Medi-Cal & LIHEAP Packet",
          household_size: "Household Size: 3",
          language_preference: "Language: English",
          situation_notes: "Standard expedited filing",
          delivery_mode: "pdf"
        }
      )

      expect(result[:mode]).to eq("pdf")
      expect(result[:cipher_algorithm]).to eq("AES-256-GCM")
      expect(result[:external_bytes_sent]).to eq(0)
      expect(result[:ciphertext_b64]).to be_present
      expect(result[:iv_b64]).to be_present
      expect(result[:auth_tag_b64]).to be_present
      expect(result[:preview_summary]).to include("0 Bytes sent externally")
    end

    it "attaches a Courier Printed Packet to the Member's CareBasket when delivery_mode is 'courier'" do
      basket = Decidim::CommonNeed::CareBasket.create!(
        decidim_component_id: 1,
        access_principle: "UNCONDITIONAL SOLIDARITY"
      )

      result = service.process_guided_paperwork(
        {
          template_name: "Veteran Services: VA Disability Claim & DD-214 Support Packet",
          delivery_mode: "courier"
        },
        care_basket: basket
      )

      expect(result[:mode]).to eq("courier")
      expect(result[:external_bytes_sent]).to eq(0)
      expect(result[:courier_item_name]).to include("Courier Printed Packet: Veteran Services")
      expect(basket.care_basket_items.count).to eq(1)
    end
  end

  describe Decidim::CommonNeed::FederationTelemetryService do
    let(:service) { Decidim::CommonNeed::FederationTelemetryService.new }

    it "returns zero-knowledge aggregate telemetry with household_pii_bytes == 0 across 14 peered nodes" do
      telemetry = service.call
      expect(telemetry[:peered_nodes_count]).to eq(14)
      expect(telemetry[:households_served]).to eq(4280)
      expect(telemetry[:shift_fill_rate_pct]).to eq(95.4)
      expect(telemetry[:surplus_rescued_lbs]).to eq(24_680)
      expect(telemetry[:household_pii_bytes]).to eq(0)
    end

    it "raises SecurityError if any forbidden PII keys (name, address, phone, email, coordinates) are passed" do
      Decidim::CommonNeed::FederationTelemetryService::FORBIDDEN_PII_KEYS.each do |pii_key|
        expect do
          service.call({ pii_key.to_sym => "Sensitive Household Data" })
        end.to raise_error(SecurityError, /Zero-Knowledge Federation violation/)
      end
    end

    it "strips nested PII keys via strip_pii when sanitizing untrusted hashes" do
      cleaned = service.strip_pii(
        node_code: "#OAK-01",
        address: "1400 62nd Ave",
        nested: { email: "member@example.org", surplus_lbs: 1840 }
      )
      expect(cleaned).not_to have_key(:address)
      expect(cleaned[:nested]).not_to have_key(:email)
      expect(cleaned[:nested][:surplus_lbs]).to eq(1840)
    end
  end

  describe Decidim::CommonNeed::NodeProvisionerService do
    it "provisions a sovereign Docker Compose stack with Decidim, PostGIS, OSRM, Photon, and Doorkeeper OAuth2 peering" do
      provisioner = Decidim::CommonNeed::NodeProvisionerService.new(
        name: "Richmond Mutual Aid Node",
        domain: "richmond.commonneed.org",
        deployment_mode: "Standalone Sovereign Docker",
        osrm_region: "Bay Area / NorCal OSRM",
        node_code: "#RCH-03"
      )

      bundle = provisioner.provision!
      expect(bundle[:node_code]).to eq("#RCH-03")
      expect(bundle[:household_pii_bytes_on_hub]).to eq(0)
      expect(bundle[:oauth_application_uid]).to start_with("doorkeeper-rch-03-")
      expect(bundle[:docker_compose_yaml]).to include("postgis/postgis:16-3.4-alpine")
      expect(bundle[:docker_compose_yaml]).to include("ghcr.io/project-osrm/osrm-backend:latest")
      expect(bundle[:docker_compose_yaml]).to include("rtuszik/photon-docker:latest")
      expect(bundle[:docker_compose_yaml]).to include('HOUSEHOLD_PII_BYTES_ON_HUB: "0"')
    end
  end
end
