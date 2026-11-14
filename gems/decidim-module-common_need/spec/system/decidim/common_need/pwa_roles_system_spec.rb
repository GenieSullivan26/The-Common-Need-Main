# frozen_string_literal: true

require "spec_helper"

RSpec.describe "The Common Need 5-Role PWA Suite System Specs", type: :system do
  describe "Unified 5-Role PWA Suite (Root Portal)" do
    before { visit "/" }

    it "renders the top 5-Role Switcher bar only on the Unified 5-Role PWA Suite" do
      expect(page).to have_css("#top-role-switcher")
      expect(page).to have_content("🛍️ Member")
      expect(page).to have_content("🚚 Volunteer")
      expect(page).to have_content("🏢 Partner")
      expect(page).to have_content("🌐 Local Node")
      expect(page).to have_content("📊 Central Hub")
    end
  end

  describe "Decidim Sign-On Security Authentication & Role-Based PWA Dispatcher" do
    before { visit "/?role=member" }

    it "renders the Decidim Sign-On Security Authentication gate (#decidim-sso-gate) for Member, Volunteer, and Partner user types" do
      expect(page).to have_css("#decidim-sso-gate")
      expect(page).to have_content("DECIDIM v0.32+ • DEVISE + VERIFICATIONS SSO")
      expect(page).to have_content("Decidim Security Sign-On")
      expect(page).to have_content("Decidim::Verifications::VolunteerCourierHandler")
      expect(page).to have_content("Decidim::Verifications::NonProfitHandler")
    end

    it "authenticates Member, Volunteer, and Partner Decidim accounts and directs each to the matching PWA based on user type" do
      member_auth = Decidim::CommonNeed::DecidimSignOnService.new(
        email: "rosa@oakland-node.org",
        password: "solidarity-oak-01"
      ).call
      expect(member_auth[:authenticated]).to eq(true)
      expect(member_auth[:user_type]).to eq("member")
      expect(member_auth[:target_portal]).to eq("Decidim::CommonNeed::MemberPortal")
      expect(member_auth[:redirect_path]).to eq("/?role=member")

      volunteer_auth = Decidim::CommonNeed::DecidimSignOnService.new(
        email: "marcus@oakland-node.org",
        password: "solidarity-oak-01"
      ).call
      expect(volunteer_auth[:authenticated]).to eq(true)
      expect(volunteer_auth[:user_type]).to eq("volunteer")
      expect(volunteer_auth[:target_portal]).to eq("Decidim::Courier::VolunteerPortal")
      expect(volunteer_auth[:redirect_path]).to eq("/?role=volunteer")

      partner_auth = Decidim::CommonNeed::DecidimSignOnService.new(
        email: "elena@eastoaklandpantry.org",
        password: "solidarity-oak-01"
      ).call
      expect(partner_auth[:authenticated]).to eq(true)
      expect(partner_auth[:user_type]).to eq("nonprofit")
      expect(partner_auth[:target_portal]).to eq("Decidim::Services::PartnerPortal")
      expect(partner_auth[:redirect_path]).to eq("/?role=nonprofit")
    end
  end

  describe "Role 1: Member PWA Portal (Decidim::CommonNeed::MemberPortal)" do
    before { visit "/?role=member" }

    it "hides the top 5-Role Switcher bar and renders Member header with NO MEANS-TESTING & UNCONDITIONAL SOLIDARITY" do
      expect(page).not_to have_css("#top-role-switcher")
      expect(page).to have_content("NO MEANS-TESTING")
      expect(page).to have_content("UNCONDITIONAL SOLIDARITY")
    end

    it "renders all 19 community taxonomy category filter pills and 4 neighborhood hubs in Tab 1 (Browse)" do
      expect(page).to have_content("All (19 Categories)")
      Decidim::CommonNeed::COMMUNITY_TAXONOMY_CATEGORIES.each do |cat_key|
        expect(page.body).to include("data-category=\"#{cat_key}\"")
      end

      expect(page).to have_content("East Oakland Collective Pantry & Commons")
      expect(page).to have_content("West County Health, Medical & Crisis Sanctuary")
      expect(page).to have_content("Fruitvale Legal, Housing, Veterans & Civic Resource Hub")
      expect(page).to have_content("San Antonio Arts, Youth, Education & Worker Center")
    end

    it "renders Tab 2 (100% Local AI & Paperwork Co-Pilot) with 5 guided templates and ZERO EXTERNAL API badge" do
      expect(page).to have_content("LOCAL NODE AI ASSISTANT (decidim-ai)")
      expect(page).to have_content("ZERO EXTERNAL API")
      expect(page).to have_content("Social Services: CalFresh / SNAP, Medi-Cal & LIHEAP Packet")
      expect(page).to have_content("Legal Aid: Eviction Defense & Record Expungement Intake")
      expect(page).to have_content("Housing: Emergency Rent Relief & Habitability Packet")
      expect(page).to have_content("Public Sector: Municipal ID & Paratransit Fee Waiver")
      expect(page).to have_content("Veteran Services: VA Disability Claim & DD-214 Support Packet")
    end

    it "renders Tab 3 (Multi-Hub Care Basket) with Low-Data Dynamic Delivery Banner, De-Commodified Care Ledger, and Handoff toggles" do
      expect(page).to have_content("LOW-DATA DYNAMIC WINDOW • ZERO MAP TILES")
      expect(page).to have_content("Window: 2:35 PM – 2:50 PM (2 Stops Away)")
      expect(page).to have_content("39 Meals + 20 N95s (29 lbs)")
      expect(page).to have_content("Bring up porch steps to door")
      expect(page).to have_content("Wait 60s at door (Mobility Aid / Senior)")
      expect(page).to have_content("DISPATCH VOLUNTEER CARE COURIER →")
    end

    it "renders Tab 4 (Partner Events Calendar) with 3-mode view switcher (List View, Calendar View, Map View) and .ics export" do
      expect(page).to have_content("📋 List View")
      expect(page).to have_content("🗓️ Calendar View")
      expect(page).to have_content("🗺️ Map View")
      expect(page).to have_css("#calendar-events-leaflet-map")
      expect(page).to have_content("⬇ iCal (.ics)")
      expect(page).to have_content("Community Harvest Dinner & Winter Seed/Compost Swap")
      expect(page).to have_content("Tenant Eviction Defense, CalFresh & Veterans VA Claim Clinic")
    end

    it "renders Tab 5 (1 Member = 1 Vote Democratic Governance) with Decidim Proposals" do
      expect(page).to have_content("1 MEMBER = 1 VOTE")
      expect(page).to have_content("DECIDIM-PROPOSALS • #206")
      expect(page).to have_content("East Oakland Local Node Routing Standard")
    end
  end

  describe "Role 2: Volunteer Courier PWA Portal (Decidim::Courier::VolunteerPortal)" do
    before { visit "/?role=volunteer" }

    it "renders OSRM Turn-by-Turn navigation, Leaflet route map, Web Speech API voice nav button, and Stop #2 confirmation without the top role switcher" do
      expect(page).not_to have_css("#top-role-switcher")
      expect(page).to have_content("THE COMMON NEED • VOLUNTEER PWA")
      expect(page).to have_content("BATCH #OAK-409")
      expect(page).to have_content("📶 Offline Ready")
      expect(page).to have_css("#leaflet-map")
      expect(page).to have_content("🔊 Voice")
      expect(page).to have_content("[ ↱ ] LEG 1 OF 3 • STEP 2/4")
      expect(page).to have_content("West County Mutual Aid Care Hub")
      expect(page).to have_content("✓ Confirm Pickup")
      expect(page).to have_content("Handoff: Walk up 4 porch steps & wait 60s at door")
    end

    it "renders Community Bulk Distribution Shifts in Volunteer Tab 2" do
      expect(page).to have_content("Community Bulk Distribution Shifts")
      expect(page).to have_content("+ Sign Up for Shift")
    end
  end

  describe "Role 3: Partner Non-Profit PWA Portal (Decidim::Services::PartnerPortal)" do
    before { visit "/?role=partner" }

    it "renders Loading Ramp Handoff verification, Surplus Publisher, Event Publisher, and Accountability Ledger without the top role switcher" do
      expect(page).not_to have_css("#top-role-switcher")
      expect(page).to have_content("THE COMMON NEED • NON-PROFIT PROVIDER PORTAL")
      expect(page).to have_content("LOCAL NODE 501(c)(3)")
      expect(page).to have_content("✓ Crates Verified & Staged at Loading Ramp")
      expect(page).to have_content("+ POST SURPLUS GOODS TO LOCAL NODE")
      expect(page).to have_content("+ Publish Event to Member Calendar →")
      expect(page).to have_content("★ 4.9 / 5.0")
    end
  end

  describe "Role 4: Local Node Admin PWA Portal (Decidim::CommonNeed::LocalNodeAdmin)" do
    before { visit "/?role=node_admin" }

    it "renders Node #OAK-01 Community Analytics, Partner 501(c)(3) Onboarding Queue, Moderation Queue, and Local Ballots without the top role switcher" do
      expect(page).not_to have_css("#top-role-switcher")
      expect(page).to have_content("EAST OAKLAND LOCAL NODE • SOVEREIGN DASHBOARD")
      expect(page).to have_content("4 Community Hubs")
      expect(page).to have_content("312 Families")
      expect(page).to have_content("94.2%")
      expect(page).to have_content("1,840 lbs / mo")
      expect(page).to have_content("Fruitvale Senior Lunch Project (Pending 501c3)")
      expect(page).to have_content("✓ Approve Partner")
    end
  end

  describe "Role 5: Central Hub Federation PWA Portal (Decidim::CommonNeed::FederationHub)" do
    before { visit "/?role=federation" }

    it "renders Federated Server Incubator, Area Support Desk (REQ #401), Network Proposals (#NET-88), and 0 Bytes PII Telemetry without the top role switcher" do
      expect(page).not_to have_css("#top-role-switcher")
      expect(page).to have_content("THE COMMON NEED • FEDERATION CENTRAL HUB")
      expect(page).to have_content("14 NODES PEERED")
      expect(page).to have_content("⚡ Generate Stack & Peer New Federated Node →")
      expect(page).to have_content("REQ #401 • INTER-NODE SURPLUS")
      expect(page).to have_content("Richmond / West County Node (#RCH-03)")
      expect(page).to have_content("DECIDIM-PROPOSALS • #NET-88")
      expect(page).to have_content("HOUSEHOLD PII ON HUB:")
      expect(page).to have_content("0 Bytes")
    end
  end

  describe "PWA Manifest & Offline Workbox/IndexedDB Service Worker Endpoints" do
    it "serves /manifest.json with standalone display and all 19 community categories" do
      visit "/manifest.json"
      parsed = JSON.parse(page.body)
      expect(parsed["name"]).to eq("The Common Need • Federated Mutual Aid Network")
      expect(parsed["display"]).to eq("standalone")
      expect(parsed["theme_color"]).to eq("#95C623")
      expect(parsed["categories"].size).to eq(19)
    end

    it "serves /service-worker.js with Workbox/IndexedDB caching for PWA shell, Leaflet tiles, and OSRM routes" do
      visit "/service-worker.js"
      expect(page.response_headers["Service-Worker-Allowed"]).to eq("/")
      expect(page.body).to include("common-need-pwa-v1")
      expect(page.body).to include("tile.openstreetmap.org")
      expect(page.body).to include("/offline_bundle")
    end
  end
end
