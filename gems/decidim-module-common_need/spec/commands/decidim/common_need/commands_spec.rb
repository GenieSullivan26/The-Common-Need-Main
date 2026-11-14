# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Decidim::CommonNeed Commands" do
  let(:current_user) { OpenStruct.new(id: 101, name: "Marcus T.") }

  describe Decidim::CommonNeed::CreateDeliveryCommand do
    let(:care_basket) do
      Decidim::CommonNeed::CareBasket.create!(
        decidim_component_id: 1,
        access_principle: "UNCONDITIONAL SOLIDARITY"
      )
    end

    let(:checkout_form) do
      Decidim::CommonNeed::CareBasketCheckoutForm.from_params(
        care_basket_id: care_basket.id,
        bring_up_porch_steps: true,
        wait_60s_at_door: true,
        dropoff_block_label: "1400 Block of 62nd Ave",
        latitude: 37.7685,
        longitude: -122.1960
      )
    end

    it "creates a Delivery batch, initializes 3 RouteStops, marks the CareBasket dispatched, and broadcasts :ok" do
      dispatched_delivery = nil
      Decidim::CommonNeed::CreateDeliveryCommand.call(checkout_form, care_basket: care_basket, current_user: current_user) do
        on(:ok) { |delivery| dispatched_delivery = delivery }
      end

      expect(dispatched_delivery).to be_present
      expect(dispatched_delivery.batch_code).to eq("BATCH #OAK-409")
      expect(dispatched_delivery.window_headline).to eq("Window: 2:35 PM – 2:50 PM (2 Stops Away)")
      expect(dispatched_delivery.handoff_instructions).to eq("Handoff: Walk up 4 porch steps & wait 60s")
      expect(dispatched_delivery.route_stops.count).to eq(3)
      expect(care_basket.state).to eq("dispatched")
      expect(Turbo::StreamsChannel.broadcasts.last[:target]).to eq("basket-delivery-updates-banner")
    end

    it "broadcasts :invalid when the form is invalid" do
      invalid_form = Decidim::CommonNeed::CareBasketCheckoutForm.from_params(care_basket_id: nil)
      status, = Decidim::CommonNeed::CreateDeliveryCommand.call(invalid_form)
      expect(status).to eq(:invalid)
    end
  end

  describe Decidim::CommonNeed::ConfirmStopCommand do
    let(:delivery) do
      Decidim::CommonNeed::Delivery.create!(
        decidim_component_id: 1,
        batch_code: "BATCH #OAK-409",
        shift_code: "SHIFT #OAK-409",
        window_headline: "Window: 2:35 PM – 2:50 PM (2 Stops Away)",
        milestone_step: 2,
        state: "hubs_loaded"
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

    let(:confirm_form) do
      Decidim::CommonNeed::ConfirmStopForm.from_params(
        route_stop_id: stop2.id,
        delivery_id: delivery.id,
        stop_number: 2
      )
    end

    it "confirms Stop #2, narrows Stop #3's window to 2:38 PM – 2:45 PM (You Are Next!), and broadcasts a zero-map-tile Turbo Stream" do
      updated_delivery = nil
      eta_payload = nil

      Decidim::CommonNeed::ConfirmStopCommand.call(
        confirm_form,
        route_stop: stop2,
        delivery: delivery,
        current_user: current_user
      ) do
        on(:ok) do |deliv, eta|
          updated_delivery = deliv
          eta_payload = eta
        end
      end

      expect(stop2.state).to eq("confirmed")
      expect(updated_delivery.milestone_step).to eq(3)
      expect(updated_delivery.state).to eq("next_stop")
      expect(updated_delivery.window_headline).to eq("Window: 2:38 PM – 2:45 PM (You Are Next!)")
      expect(stop3.scheduled_window).to eq("2:38–2:45 PM")
      expect(eta_payload[:narrowed_window]).to eq("2:38–2:45 PM")

      stream_msg = Turbo::StreamsChannel.broadcasts.last
      expect(stream_msg[:target]).to eq("basket-delivery-updates-banner")
      expect(stream_msg[:html]).to include("data-zero-map-tiles='true'")
      expect(stream_msg[:html]).to include("Window: 2:38 PM – 2:45 PM (You Are Next!)")
    end
  end

  describe Decidim::CommonNeed::PostSurplusItemCommand do
    let(:hub) do
      Decidim::CommonNeed::Hub.create!(
        decidim_component_id: 1,
        slug: "east_oakland_pantry",
        title: { "en" => "East Oakland Collective Pantry" },
        surplus_nourishment_lbs_monthly: 500
      )
    end

    let(:surplus_form) do
      Decidim::CommonNeed::SurplusItemForm.from_params(
        hub_id: hub.id,
        title: "20 Crates of Organic Heirloom Tomatoes & Collards",
        stock_quantity: 20,
        category_key: "food",
        weight_lbs: 40.0,
        latitude: 37.7651,
        longitude: -122.1755
      )
    end

    it "creates a ServiceItem, increments the Hub's monthly surplus nourishment lbs, and broadcasts to the Member Catalog" do
      created_item = nil
      Decidim::CommonNeed::PostSurplusItemCommand.call(surplus_form, hub: hub, current_user: current_user) do
        on(:ok) { |item| created_item = item }
      end

      expect(created_item).to be_present
      expect(created_item.title).to eq("20 Crates of Organic Heirloom Tomatoes & Collards")
      expect(created_item.category_key).to eq("food")
      expect(hub.surplus_nourishment_lbs_monthly).to eq(540)
      expect(Turbo::StreamsChannel.broadcasts.last[:stream]).to eq("common_need_member_catalog")
    end
  end

  describe Decidim::CommonNeed::CreatePartnerEventCommand do
    let(:event_form) do
      Decidim::CommonNeed::PartnerEventForm.from_params(
        title: "Tenant Eviction Defense & CalFresh Clinic",
        event_day: "Thu Nov 5",
        event_time_label: "5:00 PM",
        category_tags: "⚖️ LEGAL AID • 🏠 HOUSING",
        hub_slug: "fruitvale_legal",
        location_address: "3301 E 12th St",
        latitude: 37.7758,
        longitude: -122.2248
      )
    end

    it "creates a partner calendar event and broadcasts to the Member Calendar Turbo Stream" do
      created_event = nil
      Decidim::CommonNeed::CreatePartnerEventCommand.call(event_form, current_user: current_user) do
        on(:ok) { |ev| created_event = ev }
      end

      expect(created_event).to be_present
      expect(created_event.title).to eq("Tenant Eviction Defense & CalFresh Clinic")
      expect(Turbo::StreamsChannel.broadcasts.last[:stream]).to eq("common_need_member_calendar")
    end
  end

  describe Decidim::CommonNeed::VerifyAndStageCratesCommand do
    let(:delivery) do
      Decidim::CommonNeed::Delivery.create!(
        decidim_component_id: 1,
        batch_code: "BATCH #OAK-409",
        crates_staged_at_ramp: false
      )
    end

    it "marks crates_staged_at_ramp = true and broadcasts to the Partner loading ramp stream" do
      Decidim::CommonNeed::VerifyAndStageCratesCommand.call(delivery, current_user: current_user)
      expect(delivery.crates_staged_at_ramp).to be_truthy
      expect(Turbo::StreamsChannel.broadcasts.last[:stream]).to eq("common_need_partner_ramp")
    end
  end

  describe Decidim::CommonNeed::ClaimVolunteerShiftCommand do
    let(:shift_entry) do
      Decidim::CommonNeed::TimebankEntry.create!(
        decidim_component_id: 1,
        shift_title: "Sat Nov 7 • 9:00 AM — Deep East Oakland Bulk Produce Pack",
        hours_contributed: 2.0,
        state: "open"
      )
    end

    it "claims the volunteer shift, records contributed timebank hours, and broadcasts Signed Up ✓" do
      Decidim::CommonNeed::ClaimVolunteerShiftCommand.call(shift_entry, current_user: current_user, hours_contributed: 2.5)
      expect(shift_entry.state).to eq("claimed")
      expect(shift_entry.decidim_user_id).to eq(current_user.id)
      expect(shift_entry.hours_contributed).to eq(2.5)
      expect(Turbo::StreamsChannel.broadcasts.last[:html]).to include("Signed Up ✓")
    end
  end

  describe Decidim::CommonNeed::PeerFederatedNodeCommand do
    let(:node_form) do
      Decidim::CommonNeed::FederatedNodeForm.from_params(
        name: "Vallejo Solidarity Node",
        domain: "vallejo.commonneed.org",
        deployment_mode: "Standalone Sovereign Docker",
        osrm_region: "Bay Area / NorCal OSRM",
        household_pii_bytes_on_hub: 0,
        node_code: "#VAL-15"
      )
    end

    it "provisions the Docker Compose + PostGIS + OSRM stack and peers the FederatedNode with 0 bytes of household PII" do
      peered_node = nil
      bundle = nil
      Decidim::CommonNeed::PeerFederatedNodeCommand.call(node_form, current_user: current_user) do
        on(:ok) do |node, prov|
          peered_node = node
          bundle = prov
        end
      end

      expect(peered_node).to be_present
      expect(peered_node.node_code).to eq("#VAL-15")
      expect(peered_node.household_pii_bytes_on_hub).to eq(0)
      expect(bundle[:docker_compose_yaml]).to include("postgis/postgis")
      expect(bundle[:docker_compose_yaml]).to include("osrm-backend")
    end
  end

  describe Decidim::CommonNeed::DispatchInterNodeTransferCommand do
    let(:inter_node_request) do
      Decidim::CommonNeed::InterNodeRequest.create!(
        request_code: "REQ #401",
        requesting_node_code: "#RCH-03",
        requesting_node_name: "Richmond Node #RCH-03",
        need_summary: "400 N95 Masks & 20 Staple Grain Boxes",
        state: "open"
      )
    end

    let(:transfer_form) do
      Decidim::CommonNeed::InterNodeTransferForm.from_params(
        inter_node_request_id: inter_node_request.id,
        request_code: "REQ #401",
        target_node_code: "#RCH-03",
        source_node_codes: ["#OAK-01", "#BER-04"],
        manifest_summary: "400 N95 Masks & 20 Staple Grain Boxes"
      )
    end

    it "marks the InterNodeRequest fulfilled, records peered source nodes, and broadcasts to the Federation stream" do
      Decidim::CommonNeed::DispatchInterNodeTransferCommand.call(
        transfer_form,
        inter_node_request: inter_node_request,
        current_user: current_user
      )

      expect(inter_node_request.state).to eq("fulfilled")
      expect(inter_node_request.source_node_codes).to eq(["#OAK-01", "#BER-04"])
      expect(Turbo::StreamsChannel.broadcasts.last[:html]).to include("✓ Fulfilled & Synced to Local Node")
    end
  end
end
