# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Decidim::CommonNeed Queries" do
  describe Decidim::CommonNeed::NearbyHubsQuery do
    let!(:east_oakland_hub) do
      Decidim::CommonNeed::Hub.create!(
        decidim_component_id: 1,
        slug: "east_oakland_commons",
        title: { "en" => "East Oakland Collective Pantry & Commons" },
        address: "7800 MacArthur Blvd",
        coordinates: Decidim::CommonNeed::ApplicationRecord.point_from_lat_lng(37.7651, -122.1755),
        category_keys: %w(food mutual_aid co_ops garden pets)
      )
    end

    let!(:west_county_hub) do
      Decidim::CommonNeed::Hub.create!(
        decidim_component_id: 1,
        slug: "west_county_sanctuary",
        title: { "en" => "West County Health, Medical & Crisis Sanctuary" },
        address: "3115 San Pablo Ave",
        coordinates: Decidim::CommonNeed::ApplicationRecord.point_from_lat_lng(37.8215, -122.2769),
        category_keys: %w(health medical mental_health public_safety)
      )
    end

    let!(:distant_hub) do
      Decidim::CommonNeed::Hub.create!(
        decidim_component_id: 1,
        slug: "sacramento_hub",
        title: { "en" => "Sacramento Valley Pantry" },
        address: "100 Capitol Mall",
        coordinates: Decidim::CommonNeed::ApplicationRecord.point_from_lat_lng(38.5816, -121.4944),
        category_keys: %w(food)
      )
    end

    it "builds PostGIS ST_DWithin and ST_Distance SRID 4326 clauses and orders nearby hubs by distance" do
      query_obj = Decidim::CommonNeed::NearbyHubsQuery.new(
        latitude: 37.7685,
        longitude: -122.1960,
        radius_meters: 12_000
      )

      expect(query_obj.spatial_sql_clause).to include("ST_DWithin(coordinates, ST_SetSRID(ST_MakePoint(-122.196, 37.7685), 4326)::geography, 12000)")
      expect(query_obj.distance_sql_expression).to include("ST_Distance(coordinates, ST_SetSRID(ST_MakePoint(-122.196, 37.7685), 4326)::geography)")

      results = query_obj.query.to_a
      expect(results).to eq([east_oakland_hub, west_county_hub])
      expect(results).not_to include(distant_hub)
    end

    it "filters nearby hubs by category_key and keyword search_text" do
      health_results = Decidim::CommonNeed::NearbyHubsQuery.new(
        latitude: 37.7685,
        longitude: -122.1960,
        radius_meters: 12_000,
        category_key: "medical"
      ).query.to_a
      expect(health_results).to eq([west_county_hub])

      keyword_results = Decidim::CommonNeed::NearbyHubsQuery.new(
        latitude: 37.7685,
        longitude: -122.1960,
        radius_meters: 12_000,
        search_text: "MacArthur"
      ).query.to_a
      expect(keyword_results).to eq([east_oakland_hub])
    end
  end

  describe Decidim::CommonNeed::CatalogItemsQuery do
    let(:hub) do
      Decidim::CommonNeed::Hub.create!(
        decidim_component_id: 1,
        slug: "fruitvale_hub",
        title: { "en" => "Fruitvale Resource Hub" }
      )
    end

    before do
      Decidim::CommonNeed::COMMUNITY_TAXONOMY_CATEGORIES.each do |cat|
        Decidim::Services::ServiceItem.create!(
          decidim_component_id: 1,
          hub: hub,
          category_key: cat,
          title: "Offering for #{cat}",
          dietary_and_safety_tags: "Tag-#{cat}",
          stock_quantity: 10
        )
      end
    end

    it "returns all 19 community taxonomy items when category_key is 'all' and filters accurately per category" do
      all_items = Decidim::CommonNeed::CatalogItemsQuery.new(category_key: "all").query.to_a
      expect(all_items.size).to eq(19)

      Decidim::CommonNeed::COMMUNITY_TAXONOMY_CATEGORIES.each do |cat|
        q = Decidim::CommonNeed::CatalogItemsQuery.new(category_key: cat)
        expect(q.valid_taxonomy_category?).to be_truthy
        filtered = q.query.to_a
        expect(filtered.size).to eq(1)
        expect(filtered.first.category_key).to eq(cat)
      end
    end

    it "returns an empty relation for unknown taxonomy categories and supports keyword search" do
      invalid_q = Decidim::CommonNeed::CatalogItemsQuery.new(category_key: "nonexistent")
      expect(invalid_q.valid_taxonomy_category?).to be_falsy
      expect(invalid_q.query.to_a).to be_empty

      veteran_q = Decidim::CommonNeed::CatalogItemsQuery.new(category_key: "all", search_text: "veteran_services")
      expect(veteran_q.query.to_a.size).to eq(1)
    end
  end

  describe Decidim::CommonNeed::PartnerCalendarMeetingsQuery do
    it "returns all 6 default partner events and filters by day, org_slug, topic, keyword, and spatial bounding_box" do
      all_events = Decidim::CommonNeed::PartnerCalendarMeetingsQuery.new.query
      expect(all_events.size).to eq(6)

      tue_events = Decidim::CommonNeed::PartnerCalendarMeetingsQuery.new(day: "Tue Nov 3").query
      expect(tue_events.size).to eq(1)
      expect(tue_events.first[:org_slug]).to eq("east_oakland")

      sat_events = Decidim::CommonNeed::PartnerCalendarMeetingsQuery.new(day: "Sat Nov 7").query
      expect(sat_events.size).to eq(2)

      veteran_events = Decidim::CommonNeed::PartnerCalendarMeetingsQuery.new(keyword: "dd-214").query
      expect(veteran_events.size).to eq(1)
      expect(veteran_events.first[:day]).to eq("Sun Nov 8")

      bounded_events = Decidim::CommonNeed::PartnerCalendarMeetingsQuery.new(
        bounding_box: { min_lat: 37.80, max_lat: 37.85, min_lng: -122.30, max_lng: -122.25 }
      ).query
      expect(bounded_events.size).to eq(1)
      expect(bounded_events.first[:org_slug]).to eq("west_county")
    end
  end

  describe Decidim::CommonNeed::LocalNodeAnalyticsQuery do
    it "computes Local Node #OAK-01 KPI metrics (4 Community Hubs, 312 Families, 94.2% Fill Rate, 1,840 lbs/mo)" do
      metrics = Decidim::CommonNeed::LocalNodeAnalyticsQuery.new.query

      expect(metrics[:node_code]).to eq("#OAK-01")
      expect(metrics[:active_neighborhood_hubs]).to eq(4)
      expect(metrics[:active_neighborhood_hubs_label]).to eq("4 Community Hubs")
      expect(metrics[:monthly_households_served]).to eq(312)
      expect(metrics[:monthly_households_served_label]).to eq("312 Families")
      expect(metrics[:volunteer_shift_fill_rate_pct]).to eq(94.2)
      expect(metrics[:surplus_nourishment_rescued_lbs]).to eq(1840)
    end
  end
end
