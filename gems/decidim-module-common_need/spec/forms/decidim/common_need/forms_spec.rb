# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Decidim::CommonNeed Forms" do
  describe Decidim::CommonNeed::CareBasketCheckoutForm do
    let(:valid_params) do
      {
        care_basket_id: 42,
        bring_up_porch_steps: true,
        wait_60s_at_door: true,
        dropoff_block_label: "1400 Block of 62nd Ave",
        latitude: 37.7685,
        longitude: -122.1960
      }
    end

    it "validates presence of care_basket_id, dropoff_block_label, and SRID 4326 coordinates" do
      form = Decidim::CommonNeed::CareBasketCheckoutForm.from_params(valid_params)
      expect(form).to be_valid
      expect(form.zero_means_testing_verified?).to be_truthy
      expect(form.dropoff_coordinates.srid).to eq(4326)
      expect(form.dropoff_coordinates.latitude).to eq(37.7685)
      expect(form.dropoff_coordinates.longitude).to eq(-122.1960)
      expect(form.handoff_summary).to eq("Handoff: Walk up 4 porch steps & wait 60s")
    end

    it "rejects out-of-range geographic coordinates" do
      form = Decidim::CommonNeed::CareBasketCheckoutForm.from_params(valid_params.merge(latitude: 112.5))
      expect(form).to be_invalid
    end

    it "rejects prohibited means-testing or financial attributes (income, ssn, payment_token)" do
      means_tested_params = valid_params.merge(household_income: 18_000, payment_token: "tok_commercial")
      form = Decidim::CommonNeed::CareBasketCheckoutForm.from_params(means_tested_params)
      expect(form).to be_invalid
      expect(form.errors[:base].first).to match(/Means-testing or financial fields .* are strictly prohibited/)
    end
  end

  describe Decidim::CommonNeed::ConfirmStopForm do
    it "validates route_stop_id, delivery_id, and confirmed_at" do
      form = Decidim::CommonNeed::ConfirmStopForm.from_params(
        route_stop_id: 2,
        delivery_id: 409,
        stop_number: 2
      )
      expect(form).to be_valid
      expect(form.consolidation_notes).to include("Window narrowed to 2:38–2:45 PM")

      invalid_form = Decidim::CommonNeed::ConfirmStopForm.from_params(route_stop_id: nil, delivery_id: nil)
      expect(invalid_form).to be_invalid
    end
  end

  describe Decidim::CommonNeed::SurplusItemForm do
    it "validates all 19 community taxonomy categories and builds SRID 4326 pickup_coordinates" do
      Decidim::CommonNeed::COMMUNITY_TAXONOMY_CATEGORIES.each do |category_key|
        form = Decidim::CommonNeed::SurplusItemForm.from_params(
          hub_id: 1,
          title: "Community Surplus Share (#{category_key})",
          stock_quantity: 20,
          category_key: category_key,
          latitude: 37.7651,
          longitude: -122.1755
        )
        expect(form).to be_valid
        expect(form.pickup_coordinates.srid).to eq(4326)
      end
    end

    it "rejects non-positive stock_quantity or unsupported category_key" do
      form = Decidim::CommonNeed::SurplusItemForm.from_params(
        hub_id: 1,
        title: "Invalid Surplus",
        stock_quantity: 0,
        category_key: "invalid_category"
      )
      expect(form).to be_invalid
    end
  end

  describe Decidim::CommonNeed::PartnerEventForm do
    it "validates partner event metadata and generates SRID 4326 event_coordinates" do
      form = Decidim::CommonNeed::PartnerEventForm.from_params(
        title: "Community Harvest Dinner & Winter Seed Swap",
        event_day: "Thu Nov 5",
        category_tags: "🤝 MUTUAL AID • 🍎 FOOD",
        hub_slug: "east_oakland",
        location_address: "7800 MacArthur Blvd",
        latitude: 37.7651,
        longitude: -122.1755
      )
      expect(form).to be_valid
      expect(form.event_coordinates.srid).to eq(4326)
      expect(form.event_coordinates.latitude).to eq(37.7651)
    end
  end

  describe Decidim::CommonNeed::AiPaperworkForm do
    let(:five_core_templates) do
      [
        "Social Services: CalFresh / SNAP, Medi-Cal & LIHEAP Packet",
        "Legal Aid: Eviction Defense & Record Expungement Intake",
        "Housing: Emergency Rent Relief & Habitability Packet",
        "Public Sector: Municipal ID & Paratransit Fee Waiver",
        "Veteran Services: VA Disability Claim & DD-214 Support Packet"
      ]
    end

    it "validates all 5 guided paperwork templates across both pdf and courier modes" do
      five_core_templates.each do |template_title|
        %w(pdf courier).each do |mode|
          form = Decidim::CommonNeed::AiPaperworkForm.from_params(
            template_name: template_title,
            household_size: "Household Size: 3",
            language_preference: "Language: Español",
            situation_notes: "Expedited benefits & mobility packet",
            delivery_mode: mode
          )
          expect(form).to be_valid
        end
      end
    end

    it "rejects unknown paperwork templates or unsupported delivery modes" do
      form = Decidim::CommonNeed::AiPaperworkForm.from_params(
        template_name: "Commercial Loan Application",
        delivery_mode: "cloud_upload"
      )
      expect(form).to be_invalid
    end
  end

  describe Decidim::CommonNeed::FederatedNodeForm do
    it "enforces household_pii_bytes_on_hub == 0 for Zero-Knowledge Federation peering" do
      valid_form = Decidim::CommonNeed::FederatedNodeForm.from_params(
        name: "Richmond Mutual Aid Node",
        domain: "richmond.commonneed.org",
        deployment_mode: "Standalone Sovereign Docker",
        osrm_region: "Bay Area / NorCal OSRM",
        household_pii_bytes_on_hub: 0
      )
      expect(valid_form).to be_valid

      pii_form = Decidim::CommonNeed::FederatedNodeForm.from_params(
        name: "Leaky Node",
        domain: "leaky.example.org",
        household_pii_bytes_on_hub: 64
      )
      expect(pii_form).to be_invalid
      expect(pii_form.errors[:household_pii_bytes_on_hub].join(" ")).to include("must equal 0 bytes")
    end
  end

  describe Decidim::CommonNeed::InterNodeTransferForm do
    it "validates inter_node_request_id and non-empty source_node_codes" do
      form = Decidim::CommonNeed::InterNodeTransferForm.from_params(
        inter_node_request_id: 401,
        request_code: "REQ #401",
        target_node_code: "#RCH-03",
        source_node_codes: ["#OAK-01", "#BER-04"]
      )
      expect(form).to be_valid

      invalid_form = Decidim::CommonNeed::InterNodeTransferForm.from_params(
        inter_node_request_id: 401,
        source_node_codes: [""]
      )
      expect(invalid_form).to be_invalid
    end
  end
end
