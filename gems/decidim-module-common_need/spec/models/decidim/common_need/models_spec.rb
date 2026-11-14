# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Decidim::CommonNeed Models" do
  describe Decidim::CommonNeed::Hub do
    let(:coordinates) { Decidim::CommonNeed::ApplicationRecord.point_from_lat_lng(37.7651, -122.1755) }
    let(:hub) do
      described_class.new(
        decidim_component_id: 1,
        slug: "east_oakland_commons",
        title: { "en" => "East Oakland Collective Pantry & Commons" },
        subtitle: { "en" => "Food, Mutual Aid, Co-ops, Urban Garden & Pet Care" },
        address: "7800 MacArthur Blvd",
        coordinates: coordinates,
        category_keys: %w(food mutual_aid co_ops garden pets),
        member_audit_score: 4.9,
        surplus_nourishment_lbs_monthly: 640
      )
    end

    let(:described_class) { Decidim::CommonNeed::Hub }

    it "validates presence of slug, title, and valid member_audit_score range (0.0..5.0)" do
      expect(hub).to be_valid
      expect(hub.title_text(:en)).to eq("East Oakland Collective Pantry & Commons")
      expect(hub.subtitle_text(:en)).to eq("Food, Mutual Aid, Co-ops, Urban Garden & Pet Care")
    end

    it "extracts PostGIS SRID 4326 latitude and longitude from geographic coordinates" do
      expect(hub.coordinates.srid).to eq(4326)
      expect(hub.latitude).to eq(37.7651)
      expect(hub.longitude).to eq(-122.1755)
    end

    it "rejects member_audit_score outside 0.0..5.0" do
      hub.member_audit_score = 5.5
      expect(hub).to be_invalid
    end

    it "transitions verification_status via AASM between verified, on_hold, and pending" do
      expect(hub).to be_verified
      hub.hold_partner!
      expect(hub).to be_on_hold
      hub.verify_partner!
      expect(hub).to be_verified
    end

    it "supports spatial and category scopes" do
      hub.save!
      expect(described_class.verified_hubs).to include(hub)
      expect(described_class.with_category("food")).to include(hub)
      expect(described_class.within_radius_meters(37.7685, -122.1960, 12_000)).to include(hub)
    end
  end

  describe Decidim::Services::ServiceItem do
    let(:described_class) { Decidim::Services::ServiceItem }
    let(:hub) do
      Decidim::CommonNeed::Hub.create!(
        decidim_component_id: 1,
        slug: "west_county_sanctuary",
        title: { "en" => "West County Health Sanctuary" },
        coordinates: Decidim::CommonNeed::ApplicationRecord.point_from_lat_lng(37.8215, -122.2769)
      )
    end

    it "accepts all 19 Decidim community taxonomy categories" do
      expect(Decidim::CommonNeed::COMMUNITY_TAXONOMY_CATEGORIES.size).to eq(19)

      Decidim::CommonNeed::COMMUNITY_TAXONOMY_CATEGORIES.each do |category|
        item = described_class.new(
          hub: hub,
          category_key: category,
          title: "Community Share (#{category})",
          stock_quantity: 12
        )
        expect(item).to be_valid
      end
    end

    it "rejects unknown taxonomy categories and negative stock quantities" do
      invalid_item = described_class.new(
        hub: hub,
        category_key: "commercial_retail",
        title: "Invalid Commercial Listing",
        stock_quantity: -1
      )
      expect(invalid_item).to be_invalid
    end

    it "transitions stock state via AASM (available -> low_stock -> depleted -> restock)" do
      item = described_class.create!(
        hub: hub,
        category_key: "health",
        title: "N95 Particulate Respirator Masks (20-Pack)",
        stock_quantity: 25,
        interaction_mode: "stepper"
      )
      expect(item).to be_available
      expect(item.stepper_mode?).to be_truthy

      item.mark_low_stock!
      expect(item).to be_low_stock

      item.deplete_stock!
      expect(item).to be_depleted

      item.restock!
      expect(item).to be_available
    end

    it "aliases Decidim::CommonNeed::ServiceItem to Decidim::Services::ServiceItem" do
      expect(Decidim::CommonNeed::ServiceItem.ancestors).to include(Decidim::Services::ServiceItem)
    end
  end

  describe Decidim::CommonNeed::CareBasket do
    let(:described_class) { Decidim::CommonNeed::CareBasket }
    let(:basket) do
      described_class.create!(
        decidim_component_id: 1,
        access_principle: "UNCONDITIONAL SOLIDARITY",
        bring_up_porch_steps: true,
        wait_60s_at_door: true
      )
    end

    it "enforces UNCONDITIONAL SOLIDARITY and Zero-Means-Testing" do
      expect(basket).to be_valid
      expect(basket.access_principle).to eq("UNCONDITIONAL SOLIDARITY")

      basket.access_principle = "MEANS_TESTED"
      expect(basket).to be_invalid
    end

    it "fails validation if any forbidden commercial or pricing columns are present" do
      original_cols = described_class.column_names
      begin
        described_class.column_names = original_cols + ["price_cents", "means_test_score"]
        commercial_basket = described_class.new(access_principle: "UNCONDITIONAL SOLIDARITY")
        expect(commercial_basket).to be_invalid
        expect(commercial_basket.errors[:base].first).to match(/Zero-Means-Testing violation/)
      ensure
        described_class.column_names = original_cols
      end
    end

    it "recalculates the De-Commodified Care Ledger (39 Meals + 20 N95s, 28 lbs) when CareBasketItems are added" do
      basket.care_basket_items.create!(
        item_name: "Organic Collard Greens & 25lb Grain Box",
        hub_label: "Food • East Oakland Hub",
        quantity: 1,
        meals_count: 39,
        protective_gear_count: 0,
        weight_lbs: 26.0
      )
      basket.care_basket_items.create!(
        item_name: "N95 Respirator Masks (20-Pack)",
        hub_label: "Health • West County Hub",
        quantity: 1,
        meals_count: 0,
        protective_gear_count: 20,
        weight_lbs: 2.0
      )

      expect(basket.total_meals).to eq(39)
      expect(basket.total_protective_items).to eq(20)
      expect(basket.total_weight_lbs.to_i).to eq(28)
      expect(basket.ledger_summary_load).to eq("39 Meals + 20 N95s (28 lbs)")
    end

    it "formats dignity handoff instructions from porch steps and 60s wait flags" do
      expect(basket.handoff_summary).to eq("Handoff: Walk up 4 porch steps & wait 60s")

      basket.bring_up_porch_steps = false
      basket.wait_60s_at_door = false
      expect(basket.handoff_summary).to eq("Handoff: Standard door dropoff")
    end
  end

  describe "Decidim::CommonNeed::Delivery and RouteStop" do
    let(:delivery) do
      Decidim::CommonNeed::Delivery.create!(
        decidim_component_id: 1,
        batch_code: "BATCH #OAK-409",
        shift_code: "SHIFT #OAK-409",
        route_title: "Deep East Oakland → Fruitvale Loop",
        window_headline: "Window: 2:35 PM – 2:50 PM (2 Stops Away)",
        bring_up_porch_steps: true,
        wait_60s_at_door: true,
        milestone_step: 2,
        state: "hubs_loaded"
      )
    end

    let!(:stop1) do
      Decidim::CommonNeed::RouteStop.create!(
        delivery: delivery,
        stop_number: 1,
        stop_type: "pickup",
        title: "East Oakland Collective Pantry",
        scheduled_window: "2:12 PM",
        state: "confirmed"
      )
    end

    let!(:stop2) do
      Decidim::CommonNeed::RouteStop.create!(
        delivery: delivery,
        stop_number: 2,
        stop_type: "pickup",
        title: "West County Mutual Aid Care Hub",
        scheduled_window: "Est. 2:28 PM",
        state: "pending"
      )
    end

    let!(:stop3) do
      Decidim::CommonNeed::RouteStop.create!(
        delivery: delivery,
        stop_number: 3,
        stop_type: "dropoff",
        title: "Member Household • 1400 Block of 62nd Ave",
        scheduled_window: "2:35–2:50 PM",
        state: "pending"
      )
    end

    it "narrows Stop #3's delivery window to 2:38 PM – 2:45 PM (You Are Next!) when Stop #2 is confirmed" do
      expect(delivery.milestone_step).to eq(2)
      expect(stop2).to be_pending

      stop2.confirm!

      expect(stop2).to be_confirmed
      expect(delivery.milestone_step).to eq(3)
      expect(delivery).to be_next_stop
      expect(delivery.window_headline).to eq("Window: 2:38 PM – 2:45 PM (You Are Next!)")
      expect(stop3.scheduled_window).to eq("2:38–2:45 PM")
    end

    it "completes the 4-step milestone lifecycle on complete_delivery!" do
      delivery.complete_delivery!
      expect(delivery).to be_delivered
      expect(delivery.milestone_step).to eq(4)
      expect(delivery.window_headline).to eq("Delivered ✓ (Handoff Complete)")
    end
  end

  describe Decidim::CommonNeed::TimebankEntry do
    it "validates shift_title and positive hours_contributed and transitions from open to claimed" do
      entry = Decidim::CommonNeed::TimebankEntry.create!(
        decidim_component_id: 1,
        shift_title: "Sat Nov 7 • 9:00 AM — Deep East Oakland Bulk Produce Pack",
        hours_contributed: 2.0
      )
      expect(entry).to be_open
      entry.claim!
      expect(entry).to be_claimed
      entry.complete!
      expect(entry).to be_completed
    end
  end

  describe Decidim::CommonNeed::FederatedNode do
    it "strictly enforces household_pii_bytes_on_hub == 0 for Zero-Knowledge Federation" do
      node = Decidim::CommonNeed::FederatedNode.new(
        node_code: "#OAK-01",
        name: "Oakland Unified Mutual Aid Node",
        domain: "oakland.commonneed.org",
        household_pii_bytes_on_hub: 0
      )
      expect(node).to be_valid
      expect(node.zero_knowledge_telemetry_payload[:household_pii_bytes]).to eq(0)
      expect(node.zero_knowledge_telemetry_payload[:household_pii_bytes_on_hub]).to eq(0)

      node.household_pii_bytes_on_hub = 128
      expect(node).to be_invalid
    end
  end

  describe Decidim::CommonNeed::InterNodeRequest do
    it "tracks inter-node solidarity surplus transfers (REQ #401 to #RCH-03)" do
      req = Decidim::CommonNeed::InterNodeRequest.create!(
        request_code: "REQ #401",
        requesting_node_code: "#RCH-03",
        requesting_node_name: "Richmond Node #RCH-03",
        need_summary: "400 N95 Masks & 20 Staple Grain Boxes",
        source_node_codes: ["#OAK-01", "#BER-04"]
      )
      expect(req).to be_open
      req.dispatch_transfer!
      expect(req).to be_dispatched
      expect(req.dispatched_at).to be_present
      req.fulfill_transfer!
      expect(req).to be_fulfilled
    end
  end
end
