# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Filters local partner community events (Member PWA Tab 4 Calendar) by keyword,
    # date (`Tue Nov 3`, `Thu Nov 5`, `Sat Nov 7`, `Sun Nov 8`), partner org slug,
    # topic category, and spatial bounds.
    class PartnerCalendarMeetingsQuery < Decidim::Query
      SUPPORTED_DATES = [
        "Tue Nov 3",
        "Thu Nov 5",
        "Sat Nov 7",
        "Sun Nov 8"
      ].freeze

      DEFAULT_EVENTS = [
        {
          id: 101,
          title: "Community Hot Meal & Winter Coat Share + Fresh Produce Box Distribution",
          day: "Tue Nov 3",
          time_label: "Tue Nov 3 • 4:00 PM – 7:00 PM",
          org_slug: "east_oakland",
          org_name: "East Oakland Collective Pantry",
          topic: "food_mutual_aid",
          category_chip: "🍎 FOOD • 🤝 MUTUAL AID",
          location: "7800 MacArthur Blvd",
          distance_label: "1.2 mi",
          latitude: 37.7651,
          longitude: -122.1755,
          home_delivery_kit: "Hot Meal & Winter Coat Event Care Box"
        },
        {
          id: 102,
          title: "Tenant Eviction Defense, Record Expungement & CalFresh / Medi-Cal Clinic",
          day: "Thu Nov 5",
          time_label: "Thu Nov 5 • 5:30 PM – 8:00 PM",
          org_slug: "fruitvale_legal",
          org_name: "Fruitvale Legal & Housing Collective",
          topic: "legal_housing",
          category_chip: "⚖️ LEGAL AID • 🏠 HOUSING • 📋 SOCIAL SERVICES",
          location: "3301 E 12th St, Suite 204",
          distance_label: "1.4 mi",
          latitude: 37.7758,
          longitude: -122.2248,
          home_delivery_kit: "Eviction Defense & Rent Relief Packet"
        },
        {
          id: 103,
          title: "Street Medicine, Blood Pressure / Glucose Screening, Narcan & Bilingual Healing Circle",
          day: "Sat Nov 7",
          time_label: "Sat Nov 7 • 10:00 AM – 2:00 PM",
          org_slug: "west_county",
          org_name: "West County Sanctuary & Care Hub",
          topic: "health_medical",
          category_chip: "🩺 MEDICAL • 🧠 MENTAL HEALTH • 🛟 PUBLIC SAFETY",
          location: "3115 San Pablo Ave",
          distance_label: "2.1 mi",
          latitude: 37.8215,
          longitude: -122.2769,
          home_delivery_kit: "Medical Mobility & Harm-Reduction Care Pack"
        },
        {
          id: 104,
          title: "Urban Seed & Vegetable Start Swap, Companion Pet Vet Clinic & Youth Art Screenprinting",
          day: "Sat Nov 7",
          time_label: "Sat Nov 7 • 1:00 PM – 4:30 PM",
          org_slug: "san_antonio",
          org_name: "San Antonio Urban Farm & Co-op",
          topic: "garden_arts_youth",
          category_chip: "🌱 GARDEN • 🐾 PETS • 🎨 ARTS • 🎒 YOUTH",
          location: "2200 Foothill Blvd",
          distance_label: "1.7 mi",
          latitude: 37.7832,
          longitude: -122.2341,
          home_delivery_kit: "Heirloom Seed, Pet Kibble & Youth Art Kit"
        },
        {
          id: 105,
          title: "Veteran Disability Claim (DD-214) Workshop & Union Apprenticeship / OSHA Boot Fitting",
          day: "Sun Nov 8",
          time_label: "Sun Nov 8 • 11:00 AM – 3:00 PM",
          org_slug: "veterans_labor",
          org_name: "East Bay Veterans & Labor Solidarity Hall",
          topic: "veterans_employment",
          category_chip: "🎖️ VETERAN SERVICES • 🛠️ EMPLOYMENT • 🌻 CO-OPS",
          location: "4500 International Blvd",
          distance_label: "1.6 mi",
          latitude: 37.7712,
          longitude: -122.2125,
          home_delivery_kit: "Veteran Care & OSHA Work Boot Voucher Kit"
        },
        {
          id: 106,
          title: "Mobile Municipal ID Card Printer & Clipper START / Paratransit Sign-Up",
          day: "Sun Nov 8",
          time_label: "Sun Nov 8 • 12:00 PM – 4:00 PM",
          org_slug: "fruitvale_legal",
          org_name: "Fruitvale Civic Hub",
          topic: "public_education",
          category_chip: "🏛️ PUBLIC SECTOR • 📋 SOCIAL SERVICES",
          location: "Fruitvale Plaza",
          distance_label: "1.5 mi",
          latitude: 37.7749,
          longitude: -122.2242,
          home_delivery_kit: "Municipal ID & Paratransit Application Kit"
        }
      ].freeze

      attr_reader :day, :org_slug, :topic, :keyword, :bounding_box

      def initialize(day: "all", org_slug: "all", topic: "all", keyword: nil, bounding_box: nil)
        @day = day.to_s.strip.presence || "all"
        @org_slug = org_slug.to_s.strip.presence || "all"
        @topic = topic.to_s.strip.presence || "all"
        @keyword = keyword.to_s.strip.downcase
        @bounding_box = bounding_box
      end

      def query
        events = DEFAULT_EVENTS.dup
        events.select! { |ev| ev[:day] == day } unless day == "all"
        events.select! { |ev| ev[:org_slug] == org_slug } unless org_slug == "all"
        events.select! { |ev| ev[:topic] == topic } unless topic == "all"
        events.select! { |ev| matches_keyword?(ev) } if keyword.present?
        events.select! { |ev| within_bounds?(ev) } if bounding_box.is_a?(Hash)
        events
      end

      private

      def matches_keyword?(event)
        haystack = [
          event[:title],
          event[:org_name],
          event[:category_chip],
          event[:location],
          event[:day]
        ].join(" ").downcase
        haystack.include?(keyword)
      end

      def within_bounds?(event)
        min_lat = bounding_box[:min_lat] || -90.0
        max_lat = bounding_box[:max_lat] || 90.0
        min_lng = bounding_box[:min_lng] || -180.0
        max_lng = bounding_box[:max_lng] || 180.0

        event[:latitude].between?(min_lat, max_lat) && event[:longitude].between?(min_lng, max_lng)
      end
    end
  end
end
