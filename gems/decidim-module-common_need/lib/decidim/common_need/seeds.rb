# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Seeds all 19 Decidim Taxonomies, 4 Oakland Community Hubs, 19 ServiceItems,
    # CareBasket & Delivery #OAK-409 with 3 RouteStops, 6 November 2026 Partner Calendar Meetings,
    # Federated Nodes (#OAK-01, #BER-04, #RCH-03), Inter-Node Request REQ #401,
    # and Governance Proposals (#206, #OAK-09, #NET-88).
    class Seeds
      TAXONOMY_DEFINITIONS = {
        "food" => "🍎 Food (Organic Produce, Staple Grain Boxes & Nourishment)",
        "mutual_aid" => "🤝 Mutual Aid (Solidarity Hygiene, First-Aid & Power Outage Kits)",
        "co_ops" => "🌻 Co-ops (Worker Co-op Sourdough, Olive Oil & Roasts)",
        "garden" => "🌱 Garden (Heirloom Seeds, Vegetable Starts & Compost)",
        "pets" => "🐾 Pets (Companion Animal Kibble, Flea Care & Leashes)",
        "health" => "😷 Health (N95 Respirators, Clean Air Filters & Hygiene)",
        "medical" => "🩺 Medical (Mobility Walkers, Blood Pressure Cuffs & Wound Care)",
        "mental_health" => "🧠 Mental health (Bilingual Peer Counseling & Somatic Care)",
        "public_safety" => "🛟 Public safety (Narcan Overdose Reversal & Safety Escorts)",
        "legal_aid" => "⚖️ Legal aid (Eviction Defense, Expungement & Immigration)",
        "housing" => "🏠 Housing (Emergency Rent Relief & Weatherization/Mold Kits)",
        "social_services" => "📋 Social services (CalFresh/SNAP, Medi-Cal, WIC & LIHEAP)",
        "public_sector" => "🏛️ Public sector (Municipal IDs, Transit Waivers & Paratransit)",
        "veteran_services" => "🎖️ Veteran services (VA Disability Claims, DD-214 & Care Packs)",
        "employment" => "🛠️ Employment (Union Apprenticeship Prep & OSHA Work Boots/PPE)",
        "education" => "📚 Education (Refurbished Laptops, ESL/GED & Tutoring)",
        "youth_services" => "🎒 Youth services (STEM Backpacks, Infant Diapers & Mentorship)",
        "arts" => "🎨 Arts (Studio Supplies, Screenprinting & Community Murals)",
        "recreation" => "⚽ Recreation (Soccer/Basketball Gear, Yoga Mats & Park Passes)"
      }.freeze

      HUBS_DATA = [
        {
          slug: "east-oakland",
          title: { "en" => "East Oakland Collective Pantry & Commons" },
          subtitle: { "en" => "Food, Mutual Aid, Co-ops, Urban Garden & Pet Care • 1.2 mi away" },
          badge_label: "NO MEANS-TESTING",
          member_audit_score: 4.90,
          address: "7800 MacArthur Blvd, Oakland, CA",
          lat: 37.7651,
          lng: -122.1755,
          ein_number: "94-3184901",
          verification_status: "verified",
          surplus_nourishment_lbs_monthly: 1840,
          staff_hours_reclaimed_weekly: 18.5,
          category_keys: %w(food mutual_aid co_ops garden pets),
          items: [
            {
              category_key: "food",
              title: "Organic Collard Greens, Kale & 25lb Staple Grain Box",
              dietary_and_safety_tags: "Vegan / GF / Halal • Fresh Greens + Rice, Pinto Beans & Oats",
              yield_summary: "Yield: ~39 Nourishing Family Meals (28 lbs) • High Stock",
              stock_quantity: 24,
              meals_count: 39,
              weight_lbs: 28.0,
              protective_gear_count: 0,
              interaction_mode: "stepper",
              cta_label: "1"
            },
            {
              category_key: "mutual_aid",
              title: "Neighborhood Solidarity Hygiene, First-Aid & Power Outage Kit",
              dietary_and_safety_tags: "Community-Packed Mutual Aid Tote • Solar Lantern & Battery Bank",
              yield_summary: "Yield: Household Resilience & Neighbor Check-In Kit • Available",
              stock_quantity: 18,
              meals_count: 0,
              weight_lbs: 6.0,
              protective_gear_count: 1,
              interaction_mode: "add_share",
              cta_label: "+ Add Share"
            },
            {
              category_key: "co_ops",
              title: "Worker Co-op Sourdough Loaves, Olive Oil & Bulk Roast Share",
              dietary_and_safety_tags: "East Bay Cooperative Network • Baked & Packed by Worker-Owners",
              yield_summary: "Yield: 2 Whole Wheat Loaves + 16oz Olive Oil • Cooperative Surplus",
              stock_quantity: 15,
              meals_count: 8,
              weight_lbs: 4.5,
              protective_gear_count: 0,
              interaction_mode: "add_share",
              cta_label: "+ Add Share"
            },
            {
              category_key: "garden",
              title: "Urban Garden Seed Kit, 12 Vegetable Starts & Organic Compost",
              dietary_and_safety_tags: "Heirloom Tomatoes, Collards, Cilantro & 20lb Soil Amendments",
              yield_summary: "Yield: Home/Community Plot Food Sovereignty Kit • Available",
              stock_quantity: 20,
              meals_count: 0,
              weight_lbs: 20.0,
              protective_gear_count: 0,
              interaction_mode: "add_share",
              cta_label: "+ Add Share"
            },
            {
              category_key: "pets",
              title: "Companion Animal Kibble (20lb Dog/Cat), Flea Care & Leash Kit",
              dietary_and_safety_tags: "Grain-Free Kibble + Wet Food + Topical Flea Prevention",
              yield_summary: "Yield: 3-Week Companion Pet Nutrition & Care Supply",
              stock_quantity: 16,
              meals_count: 0,
              weight_lbs: 20.0,
              protective_gear_count: 0,
              interaction_mode: "add_share",
              cta_label: "+ Add Share"
            }
          ]
        },
        {
          slug: "west-county",
          title: { "en" => "West County Health, Medical & Crisis Sanctuary" },
          subtitle: { "en" => "Health, Medical Equipment, Mental Health & Public Safety • 2.4 mi away" },
          badge_label: "IMMUNOCOMPROMISED PRIORITY",
          member_audit_score: 5.00,
          address: "3115 San Pablo Ave, Oakland, CA",
          lat: 37.8215,
          lng: -122.2769,
          ein_number: "94-4102938",
          verification_status: "verified",
          surplus_nourishment_lbs_monthly: 620,
          staff_hours_reclaimed_weekly: 14.0,
          category_keys: %w(health medical mental_health public_safety),
          items: [
            {
              category_key: "health",
              title: "N95 Particulate Respirator Masks (20-Pack) & MERV-13 Air Filter",
              dietary_and_safety_tags: "NIOSH Approved Respirators + Clean Air Box Fan Filter",
              yield_summary: "Yield: Household Respiratory & Smoke Defense • High Stock",
              stock_quantity: 40,
              meals_count: 0,
              weight_lbs: 1.0,
              protective_gear_count: 20,
              interaction_mode: "stepper",
              cta_label: "1"
            },
            {
              category_key: "medical",
              title: "Folding Mobility Walker, Blood Pressure Cuff & Wound Care Kit",
              dietary_and_safety_tags: "ADA Durable Medical Equipment + Home Clinical Diagnostics",
              yield_summary: "Yield: Home Medical Recovery & Mobility Support • Sanitized",
              stock_quantity: 12,
              meals_count: 0,
              weight_lbs: 8.5,
              protective_gear_count: 3,
              interaction_mode: "add_share",
              cta_label: "+ Request Item"
            },
            {
              category_key: "mental_health",
              title: "Bilingual Peer Trauma Counseling & Somatic Grounding Care Kit",
              dietary_and_safety_tags: "Confidential 1-on-1 Therapist/Peer Session + Weighted Blanket",
              yield_summary: "Yield: Non-Carceral Emotional Support & Stress Relief Delivery",
              stock_quantity: 15,
              meals_count: 0,
              weight_lbs: 12.0,
              protective_gear_count: 1,
              interaction_mode: "add_share",
              cta_label: "+ Book & Deliver"
            },
            {
              category_key: "public_safety",
              title: "Narcan Overdose Reversal (2-Pack), Fire Blanket & Night Escort",
              dietary_and_safety_tags: "Community Harm Reduction + Senior/Shift-Worker Accompaniment",
              yield_summary: "Yield: Neighborhood Life-Safety & Non-Police De-Escalation",
              stock_quantity: 30,
              meals_count: 0,
              weight_lbs: 2.5,
              protective_gear_count: 2,
              interaction_mode: "add_share",
              cta_label: "+ Add Safety Kit"
            }
          ]
        },
        {
          slug: "fruitvale",
          title: { "en" => "Fruitvale Legal, Housing, Veterans & Civic Resource Hub" },
          subtitle: { "en" => "Legal Aid, Housing, Social Services, Public Sector & Veterans • 1.5 mi away" },
          badge_label: "ADVOCACY & PAPERWORK",
          member_audit_score: 4.95,
          address: "3301 E 12th St, Oakland, CA",
          lat: 37.7756,
          lng: -122.2241,
          ein_number: "94-5291044",
          verification_status: "verified",
          surplus_nourishment_lbs_monthly: 480,
          staff_hours_reclaimed_weekly: 22.0,
          category_keys: %w(legal_aid housing social_services public_sector veteran_services),
          items: [
            {
              category_key: "legal_aid",
              title: "Eviction Defense, Record Expungement & Immigration Legal Clinic",
              dietary_and_safety_tags: "Unlawful Detainer Answer + Wage Theft & Asylum Legal Aid",
              yield_summary: "Yield: Licensed Legal Representation + Courier Court Filing",
              stock_quantity: 25,
              meals_count: 0,
              weight_lbs: 0.5,
              protective_gear_count: 0,
              interaction_mode: "ai_paperwork",
              cta_label: "🤖 Start Legal",
              paperwork_template_name: "Legal Aid: Eviction Defense & Record Expungement Intake"
            },
            {
              category_key: "housing",
              title: "Emergency Rent Relief Application & Home Weatherization/Mold Kit",
              dietary_and_safety_tags: "Tenant Habitability Repair Kit + Back-Rent Stabilization Grant",
              yield_summary: "Yield: Eviction Prevention + Delivered Dehumidifier/Draft Seals",
              stock_quantity: 20,
              meals_count: 0,
              weight_lbs: 9.0,
              protective_gear_count: 0,
              interaction_mode: "ai_paperwork",
              cta_label: "🤖 Housing Help",
              paperwork_template_name: "Housing: Emergency Rent Relief & Habitability Packet"
            },
            {
              category_key: "social_services",
              title: "CalFresh / SNAP, Medi-Cal, WIC & LIHEAP Utility Arrears Filing",
              dietary_and_safety_tags: "Local AI Auto-Fill + Bilingual Caseworker Verification",
              yield_summary: "Yield: 3-Day Expedited Benefits + Courier Printed Form Delivery",
              stock_quantity: 50,
              meals_count: 0,
              weight_lbs: 0.5,
              protective_gear_count: 0,
              interaction_mode: "ai_paperwork",
              cta_label: "🤖 Auto-Fill",
              paperwork_template_name: "Social Services: CalFresh / SNAP, Medi-Cal & LIHEAP Packet"
            },
            {
              category_key: "public_sector",
              title: "Municipal City ID, Clipper START Transit & Paratransit Enrollment",
              dietary_and_safety_tags: "City/County Fee-Waiver Vouchers + East Bay Paratransit Setup",
              yield_summary: "Yield: Official Municipal ID + No-Cost Regional Transit Access",
              stock_quantity: 35,
              meals_count: 0,
              weight_lbs: 0.5,
              protective_gear_count: 0,
              interaction_mode: "ai_paperwork",
              cta_label: "🤖 Enroll Now",
              paperwork_template_name: "Public Sector: Municipal ID & Paratransit Fee Waiver"
            },
            {
              category_key: "veteran_services",
              title: "Veterans VA Disability Claim Filing, DD-214 & Supportive Care Pack",
              dietary_and_safety_tags: "Accredited Veteran Peer Advocate + Cold-Weather & Pantry Bundle",
              yield_summary: "Yield: VA Benefits Navigation + Home-Delivered Veteran Care Tote",
              stock_quantity: 20,
              meals_count: 12,
              weight_lbs: 10.0,
              protective_gear_count: 2,
              interaction_mode: "ai_paperwork",
              cta_label: "🤖 VA Support",
              paperwork_template_name: "Veteran Services: VA Disability Claim & DD-214 Support Packet"
            }
          ]
        },
        {
          slug: "san-antonio",
          title: { "en" => "San Antonio Arts, Youth, Education & Worker Center" },
          subtitle: { "en" => "Employment, Education, Youth Services, Arts & Recreation • 1.8 mi away" },
          badge_label: "CULTURE, YOUTH & JOBS",
          member_audit_score: 4.92,
          address: "2200 Foothill Blvd, Oakland, CA",
          lat: 37.7854,
          lng: -122.2385,
          ein_number: "94-6892311",
          verification_status: "verified",
          surplus_nourishment_lbs_monthly: 540,
          staff_hours_reclaimed_weekly: 16.5,
          category_keys: %w(employment education youth_services arts recreation),
          items: [
            {
              category_key: "employment",
              title: "Union Apprenticeship Prep, OSHA-10 Work Boots/PPE & Resume Clinic",
              dietary_and_safety_tags: "Steel-Toe Boots, High-Vis Vest, Hardhat + Hiring Hall Referral",
              yield_summary: "Yield: Job-Site Safety Gear Delivered + Union Career Placement",
              stock_quantity: 18,
              meals_count: 0,
              weight_lbs: 6.5,
              protective_gear_count: 3,
              interaction_mode: "add_share",
              cta_label: "+ Add Work Kit"
            },
            {
              category_key: "education",
              title: "Refurbished Linux Laptop, ESL/GED Study Books & Tutoring Pass",
              dietary_and_safety_tags: "LibreOffice + Offline Kiwix Wikipedia + Bilingual Adult/Youth Prep",
              yield_summary: "Yield: Permanent Household Computer + Weekly Study Support",
              stock_quantity: 14,
              meals_count: 0,
              weight_lbs: 5.5,
              protective_gear_count: 0,
              interaction_mode: "add_share",
              cta_label: "+ Request Kit"
            },
            {
              category_key: "youth_services",
              title: "Youth STEM Backpack, Infant Diapers/Formula & After-School Pass",
              dietary_and_safety_tags: "Size 1–5 Diapers + Formula + K-12 School Supplies & Mentorship",
              yield_summary: "Yield: Complete Early Childhood & Youth Development Bundle",
              stock_quantity: 22,
              meals_count: 10,
              weight_lbs: 9.0,
              protective_gear_count: 0,
              interaction_mode: "add_share",
              cta_label: "+ Add Youth Pack"
            },
            {
              category_key: "arts",
              title: "Community Screenprinting, Acrylic Paint & Muralist Supply Box",
              dietary_and_safety_tags: "24-Color Acrylics, Heavyweight Sketchbooks, Brushes & Linocut Kit",
              yield_summary: "Yield: Home Studio Art Kit + Open Printmaking Workshop Access",
              stock_quantity: 20,
              meals_count: 0,
              weight_lbs: 5.0,
              protective_gear_count: 0,
              interaction_mode: "add_share",
              cta_label: "+ Add Art Box"
            },
            {
              category_key: "recreation",
              title: "Neighborhood Soccer/Basketball Gear, Yoga Mat & Regional Park Pass",
              dietary_and_safety_tags: "Size 5 Soccer Ball, Pump, Non-Slip Yoga Mat & Swim/Park Vouchers",
              yield_summary: "Yield: Family Outdoor Recreation & Movement Equipment",
              stock_quantity: 25,
              meals_count: 0,
              weight_lbs: 4.0,
              protective_gear_count: 0,
              interaction_mode: "add_share",
              cta_label: "+ Add Rec Kit"
            }
          ]
        }
      ].freeze

      PARTNER_CALENDAR_EVENTS_DATA = [
        {
          day_label: "Tue Nov 3",
          time_badge: "Tue Nov 3 • 4:00 PM – 7:00 PM",
          start_time: Time.utc(2026, 11, 3, 16, 0),
          end_time: Time.utc(2026, 11, 3, 19, 0),
          org_key: "east_oakland",
          topic_key: "food",
          category_chip: "🍎 FOOD & 🌱 GARDEN",
          title: "Community Harvest Dinner & Winter Seed/Compost Swap",
          host_line: "Hosted by: East Oakland Collective Pantry • 📍 7800 MacArthur Blvd (1.2 mi)",
          address: "7800 MacArthur Blvd, Oakland, CA",
          lat: 37.7651,
          lng: -122.1755,
          description: "Hot plantain & black bean dinner served to all neighbors, plus winter brassica seedlings, soil testing, and take-home produce boxes.",
          accessibility_badge: "✓ Childcare Space • ✓ ADA Ramp • 42 / 80 Spots Registered",
          available_slots: 80
        },
        {
          day_label: "Thu Nov 5",
          time_badge: "Thu Nov 5 • 1:00 PM – 5:00 PM",
          start_time: Time.utc(2026, 11, 5, 13, 0),
          end_time: Time.utc(2026, 11, 5, 17, 0),
          org_key: "fruitvale",
          topic_key: "legal",
          category_chip: "⚖️ LEGAL AID • 🏠 HOUSING • 🎖️ VETERANS",
          title: "Tenant Eviction Defense, CalFresh & Veterans VA Claim Clinic",
          host_line: "Hosted by: Fruitvale Legal & Civic Hub • 📍 3301 E 12th St / Hybrid (1.5 mi)",
          address: "3301 E 12th St, Oakland, CA",
          lat: 37.7756,
          lng: -122.2241,
          description: "1-on-1 licensed housing attorneys, accredited VA disability representatives, and bilingual CalFresh/Medi-Cal/LIHEAP enrollment navigators.",
          accessibility_badge: "✓ Español / Mam / Vietnamese Interpretation • 19 / 40 Slots Open",
          available_slots: 40
        },
        {
          day_label: "Sat Nov 7",
          time_badge: "Sat Nov 7 • 10:00 AM – 2:00 PM",
          start_time: Time.utc(2026, 11, 7, 10, 0),
          end_time: Time.utc(2026, 11, 7, 14, 0),
          org_key: "west_county",
          topic_key: "health",
          category_chip: "🩺 MEDICAL • 🧠 MENTAL HEALTH • 🛟 SAFETY",
          title: "Street Medicine, Mobility Walker Fitting & Narcan Harm-Reduction Fair",
          host_line: "Hosted by: West County Health Sanctuary • 📍 3115 San Pablo Ave (2.4 mi)",
          address: "3115 San Pablo Ave, Oakland, CA",
          lat: 37.8215,
          lng: -122.2769,
          description: "No-cost blood pressure & glucose screenings, custom ADA walker/cane fittings, somatic trauma healing circles, and N95 + Narcan distribution.",
          accessibility_badge: "✓ Outdoor / HEPA Filtered • ✓ Fragrance-Free Zone • Open Walk-In",
          available_slots: 100
        },
        {
          day_label: "Sat Nov 7",
          time_badge: "Sat Nov 7 • 1:00 PM – 5:00 PM",
          start_time: Time.utc(2026, 11, 7, 13, 0),
          end_time: Time.utc(2026, 11, 7, 17, 0),
          org_key: "san_antonio",
          topic_key: "youth",
          category_chip: "🎨 ARTS • 🎒 YOUTH • 🛠️ EMPLOYMENT • 📚 EDUCATION",
          title: "Union Apprenticeship Expo, Linux Laptop Lab & Youth Screenprinting Jam",
          host_line: "Hosted by: San Antonio Worker & Youth Center • 📍 2200 Foothill Blvd (1.8 mi)",
          address: "2200 Foothill Blvd, Oakland, CA",
          lat: 37.7854,
          lng: -122.2385,
          description: "Meet union building trades coordinators, pick up OSHA-10 work boots, get a refurbished Linux laptop configured, and join the youth poster workshop.",
          accessibility_badge: "✓ Youth Childcare & Playroom • ✓ Certificate of Attendance",
          available_slots: 60
        },
        {
          day_label: "Sun Nov 8",
          time_badge: "Sun Nov 8 • 11:00 AM – 3:00 PM",
          start_time: Time.utc(2026, 11, 8, 11, 0),
          end_time: Time.utc(2026, 11, 8, 15, 0),
          org_key: "east_oakland",
          topic_key: "food",
          category_chip: "🐾 PETS • ⚽ RECREATION • 🌻 CO-OPS",
          title: "Mobile Street Vet Clinic, Neighborhood Soccer & Worker Co-op Bake Share",
          host_line: "Hosted by: East Oakland Commons & Co-op Network • 📍 Arroyo Viejo Park (0.9 mi)",
          address: "Arroyo Viejo Park, Oakland, CA",
          lat: 37.7582,
          lng: -122.1795,
          description: "No-cost dog/cat vaccinations, microchipping, and 20lb kibble bags alongside all-ages pickup soccer, yoga in the park, and worker co-op sourdough bread.",
          accessibility_badge: "✓ Leash & Carrier Provided • ✓ All Ages Welcome",
          available_slots: 120
        },
        {
          day_label: "Sun Nov 8",
          time_badge: "Sun Nov 8 • 12:00 PM – 4:00 PM",
          start_time: Time.utc(2026, 11, 8, 12, 0),
          end_time: Time.utc(2026, 11, 8, 16, 0),
          org_key: "fruitvale",
          topic_key: "legal",
          category_chip: "🏛️ PUBLIC SECTOR • 📋 SOCIAL SERVICES",
          title: "Mobile Municipal ID Card Printer & Clipper START / Paratransit Sign-Up",
          host_line: "Hosted by: Fruitvale Civic Hub • 📍 Fruitvale Plaza (1.5 mi)",
          address: "Fruitvale Plaza, Oakland, CA",
          lat: 37.7749,
          lng: -122.2248,
          description: "On-the-spot photo and printing for official Oakland Municipal ID cards (fee waived) and instant activation of regional transit passes.",
          accessibility_badge: "✓ Same-Day Card Printing • ✓ Wheelchair Accessible Plaza",
          available_slots: 90
        }
      ].freeze

      OSRM_MANEUVERS_DATA = [
        {
          counter: "[ ↱ ] LEG 1 OF 3 • STEP 1/4",
          dist: "5.8 mi (9 min)",
          text: "Head northwest on MacArthur Blvd and merge onto I-580 W toward West Oakland."
        },
        {
          counter: "[ ↖ ] LEG 1 OF 3 • STEP 2/4",
          dist: "0.6 mi (2 min)",
          text: "Take Exit 19C toward West St / San Pablo Ave and merge onto 36th St toward Stop #2."
        },
        {
          counter: "[ ↰ ] LEG 1 OF 3 • STEP 3/4",
          dist: "0.4 mi (1 min)",
          text: "Turn left onto San Pablo Ave toward 31st St."
        },
        {
          counter: "[ 🏁 ] LEG 1 OF 3 • STEP 4/4",
          dist: "0.0 mi (Arrive)",
          text: "Arrive at Stop #2: West County Mutual Aid Care Hub (3115 San Pablo Ave) on right."
        }
      ].freeze

      GOVERNANCE_PROPOSALS_DATA = [
        {
          reference_code: "DECIDIM-PROPOSALS • #206",
          scope_type: "local_member",
          title: "East Oakland Local Node Routing Standard",
          body: "Maintain local data sovereignty on East Oakland server instance while federating aggregate nourishment impact up to The Common Need network.",
          quorum_label: "Quorum: 96% Met",
          support_votes_count: 412,
          oppose_votes_count: 14
        },
        {
          reference_code: "LOCAL BALLOT #OAK-09",
          scope_type: "local_node",
          title: "Expand East Oakland Delivery Radius to 90th Ave",
          body: "Proposal to extend volunteer courier batch routes eastward to cover senior housing complexes along International Blvd.",
          quorum_label: "Quorum: 92% Met",
          support_votes_count: 289,
          oppose_votes_count: 19
        },
        {
          reference_code: "DECIDIM-PROPOSALS • #NET-88",
          scope_type: "network_federation",
          title: "Inter-Node Solidarity & Emergency Grain Reserve Protocol",
          body: "Mandate that federated nodes with >20% monthly staple surplus automatically pledge 5% to a regional rapid-response pool.",
          quorum_label: "14/14 NODES VOTING",
          support_votes_count: 3842,
          oppose_votes_count: 245
        }
      ].freeze

      attr_reader :participatory_space

      def initialize(participatory_space: nil)
        @participatory_space = participatory_space
      end

      def call
        component = find_or_create_common_need_component!
        author = find_or_create_seed_author!(component)

        seed_taxonomies!(component)
        hubs_by_slug = seed_hubs_and_service_items!(component, author)
        seed_pending_partner_hub!(component, author)
        seed_basket_and_deliveries!(component, author, hubs_by_slug)
        seed_timebank_shifts!(component, author)
        seed_partner_calendar_meetings!(component, author)
        seed_federated_nodes_and_requests!(component)
        seed_governance_proposals!(component, author)
      end

      private

      def organization
        @organization ||= participatory_space&.organization ||
                          (defined?(Decidim::Organization) && Decidim::Organization.first)
      end

      def find_or_create_common_need_component!
        if participatory_space && defined?(Decidim::Component)
          Decidim::Component.find_or_create_by!(
            participatory_space: participatory_space,
            manifest_name: "common_need"
          ) do |comp|
            comp.name = { "en" => "The Common Need • Federated Mutual Aid Network" }
            comp.published_at = Time.current
          end
        elsif defined?(Decidim::Component) && Decidim::Component.where(manifest_name: "common_need").any?
          Decidim::Component.where(manifest_name: "common_need").first
        else
          OpenStruct.new(id: 1, organization: organization, participatory_space: participatory_space)
        end
      end

      def find_or_create_seed_author!(component)
        if defined?(Decidim::User) && component.respond_to?(:organization) && component.organization
          Decidim::User.find_or_create_by!(
            organization: component.organization,
            email: "marcus.courier@commonneed.org"
          ) do |u|
            u.name = "Marcus T. (Volunteer Courier)"
            u.nickname = "marcus_oak_01"
            u.password = "Solidarity2026!CommonNeed"
            u.password_confirmation = "Solidarity2026!CommonNeed"
            u.confirmed_at = Time.current
            u.tos_agreement = true
          end
        else
          OpenStruct.new(id: 1, class: OpenStruct.new(name: "Decidim::UserBaseEntity"))
        end
      end

      def seed_taxonomies!(component)
        return unless defined?(Decidim::Taxonomy) && component.respond_to?(:organization) && component.organization

        root_taxonomy = Decidim::Taxonomy.find_or_create_by!(
          organization: component.organization,
          name: { "en" => "Community Mutual Aid Categories (19)" },
          parent_id: nil
        )

        TAXONOMY_DEFINITIONS.each do |key, label|
          Decidim::Taxonomy.find_or_create_by!(
            organization: component.organization,
            parent: root_taxonomy,
            name: { "en" => label, "key" => key }
          )
        end
      rescue StandardError
        # Gracefully continue if Decidim::Taxonomy table differs across minor versions
        nil
      end

      def seed_hubs_and_service_items!(component, author)
        hubs_by_slug = {}

        HUBS_DATA.each do |hub_attrs|
          hub = Decidim::CommonNeed::Hub.find_or_initialize_by(
            decidim_component_id: component.id,
            slug: hub_attrs[:slug]
          )
          hub.assign_attributes(
            decidim_author_id: author.id,
            decidim_author_type: author.is_a?(OpenStruct) ? "Decidim::UserBaseEntity" : author.class.base_class.name,
            title: hub_attrs[:title],
            subtitle: hub_attrs[:subtitle],
            badge_label: hub_attrs[:badge_label],
            member_audit_score: hub_attrs[:member_audit_score],
            address: hub_attrs[:address],
            coordinates: Decidim::CommonNeed::ApplicationRecord.point_from_lat_lng(hub_attrs[:lat], hub_attrs[:lng]),
            ein_number: hub_attrs[:ein_number],
            verification_status: hub_attrs[:verification_status],
            surplus_nourishment_lbs_monthly: hub_attrs[:surplus_nourishment_lbs_monthly],
            staff_hours_reclaimed_weekly: hub_attrs[:staff_hours_reclaimed_weekly],
            category_keys: hub_attrs[:category_keys]
          )
          hub.save!
          hubs_by_slug[hub.slug] = hub

          hub_attrs[:items].each do |item_attrs|
            item = Decidim::Services::ServiceItem.find_or_initialize_by(
              decidim_component_id: component.id,
              decidim_common_need_hub_id: hub.id,
              category_key: item_attrs[:category_key],
              title: item_attrs[:title]
            )
            item.assign_attributes(
              decidim_author_id: author.id,
              decidim_author_type: author.is_a?(OpenStruct) ? "Decidim::UserBaseEntity" : author.class.base_class.name,
              dietary_and_safety_tags: item_attrs[:dietary_and_safety_tags],
              yield_summary: item_attrs[:yield_summary],
              stock_quantity: item_attrs[:stock_quantity],
              meals_count: item_attrs[:meals_count],
              weight_lbs: item_attrs[:weight_lbs],
              protective_gear_count: item_attrs[:protective_gear_count],
              interaction_mode: item_attrs[:interaction_mode],
              cta_label: item_attrs[:cta_label],
              paperwork_template_name: item_attrs[:paperwork_template_name],
              pickup_coordinates: hub.coordinates,
              state: "available"
            )
            item.save!
          end
        end

        hubs_by_slug
      end

      def seed_pending_partner_hub!(component, author)
        pending_hub = Decidim::CommonNeed::Hub.find_or_initialize_by(
          decidim_component_id: component.id,
          slug: "fruitvale-senior-lunch-project"
        )
        pending_hub.assign_attributes(
          decidim_author_id: author.id,
          decidim_author_type: author.is_a?(OpenStruct) ? "Decidim::UserBaseEntity" : author.class.base_class.name,
          title: { "en" => "Fruitvale Senior Lunch Project (Pending 501c3)" },
          subtitle: { "en" => "Submitted Oct 28 • EIN: 94-7728190" },
          badge_label: "PENDING 501(c)(3) VERIFICATION",
          member_audit_score: 4.85,
          address: "3410 International Blvd, Oakland, CA",
          coordinates: Decidim::CommonNeed::ApplicationRecord.point_from_lat_lng(37.7742, -122.2215),
          ein_number: "94-7728190",
          verification_status: "pending",
          surplus_nourishment_lbs_monthly: 320,
          staff_hours_reclaimed_weekly: 8.0,
          category_keys: %w(food social_services)
        )
        pending_hub.save!
      end

      def seed_basket_and_deliveries!(component, author, hubs_by_slug)
        east_oakland_hub = hubs_by_slug["east-oakland"]
        west_county_hub = hubs_by_slug["west-county"]

        collards_item = Decidim::Services::ServiceItem.find_by(
          decidim_component_id: component.id,
          category_key: "food"
        )
        masks_item = Decidim::Services::ServiceItem.find_by(
          decidim_component_id: component.id,
          category_key: "health"
        )

        basket = Decidim::CommonNeed::CareBasket.find_or_initialize_by(
          decidim_component_id: component.id,
          decidim_user_id: author.id,
          routing_node_code: "#OAK-01"
        )
        basket.assign_attributes(
          bring_up_porch_steps: true,
          wait_60s_at_door: true,
          access_principle: "UNCONDITIONAL SOLIDARITY",
          state: "open"
        )
        basket.save!

        item1 = Decidim::CommonNeed::CareBasketItem.find_or_initialize_by(
          care_basket: basket,
          item_name: "Organic Collard Greens, Kale & Grain Box"
        )
        item1.assign_attributes(
          service_item: collards_item,
          hub_label: "Food • East Oakland Collective Pantry",
          badge_summary: "28 lbs / 39 Meals",
          quantity: 1,
          meals_count: 39,
          weight_lbs: 28.0,
          protective_gear_count: 0
        )
        item1.save!

        item2 = Decidim::CommonNeed::CareBasketItem.find_or_initialize_by(
          care_basket: basket,
          item_name: "N95 Particulate Respirator Masks (20-Pack)"
        )
        item2.assign_attributes(
          service_item: masks_item,
          hub_label: "Health • West County Health Sanctuary",
          badge_summary: "20 N95s / Air",
          quantity: 1,
          meals_count: 0,
          weight_lbs: 1.0,
          protective_gear_count: 20
        )
        item2.save!

        basket.recalculate_ledger!

        delivery = Decidim::CommonNeed::Delivery.find_or_initialize_by(
          decidim_component_id: component.id,
          batch_code: "BATCH #OAK-409"
        )
        delivery.assign_attributes(
          care_basket: basket,
          decidim_user_id: author.id,
          volunteer_user_id: author.id,
          shift_code: "SHIFT #OAK-409",
          route_title: "Deep East Oakland → Fruitvale Loop",
          window_start_at: Time.utc(2026, 11, 3, 14, 35),
          window_end_at: Time.utc(2026, 11, 3, 14, 50),
          window_headline: "Window: 2:35 PM – 2:50 PM (2 Stops Away)",
          bring_up_porch_steps: true,
          wait_60s_at_door: true,
          handoff_instructions: "Handoff: Walk up 4 porch steps & wait 60s",
          dropoff_block_label: "1400 Block of 62nd Ave",
          dropoff_coordinates: Decidim::CommonNeed::ApplicationRecord.point_from_lat_lng(37.7685, -122.1960),
          total_duration_minutes: 42,
          total_distance_miles: 4.6,
          osrm_polyline: "[[37.7651,-122.1755],[37.8215,-122.2769],[37.7685,-122.1960]]",
          osrm_maneuvers: OSRM_MANEUVERS_DATA,
          milestone_step: 2,
          crates_staged_at_ramp: false,
          state: "hubs_loaded"
        )
        delivery.save!

        stops_data = [
          {
            stop_number: 1,
            stop_type: "pickup",
            hub: east_oakland_hub,
            title: "East Oakland Collective Pantry",
            address_label: "7800 MacArthur Blvd • 4 Crates Loaded",
            manifest_summary: "Crates loaded • Window set to 2:35–2:50 PM",
            handoff_note: "Pull from Shelf: 4x Produce Bundles, 2x Staple Grain Boxes",
            scheduled_window: "2:12 PM",
            confirmed_at: Time.utc(2026, 11, 3, 14, 12),
            lat: 37.7651,
            lng: -122.1755,
            state: "confirmed"
          },
          {
            stop_number: 2,
            stop_type: "pickup",
            hub: west_county_hub,
            title: "West County Mutual Aid Care Hub",
            address_label: "3115 San Pablo Ave (By 2:30 PM)",
            manifest_summary: "Consolidating N95 masks • Confirmation narrows your window",
            handoff_note: "2 sealed medical/hygiene parcels (N95 Masks & Care Kits)",
            scheduled_window: "EST. 2:26 PM",
            confirmed_at: nil,
            lat: 37.8215,
            lng: -122.2769,
            state: "pending"
          },
          {
            stop_number: 3,
            stop_type: "dropoff",
            hub: nil,
            title: "Member Household • 1400 Block of 62nd Ave",
            address_label: "1400 Block of 62nd Ave",
            manifest_summary: "Multi-Hub Care Basket (2 Shares: 39 Meals + 20 N95s)",
            handoff_note: "Handoff: Walk up 4 porch steps & wait 60s",
            scheduled_window: "2:35–2:50 PM",
            confirmed_at: nil,
            lat: 37.7685,
            lng: -122.1960,
            state: "pending"
          }
        ]

        stops_data.each do |s|
          stop = Decidim::CommonNeed::RouteStop.find_or_initialize_by(
            delivery: delivery,
            stop_number: s[:stop_number]
          )
          stop.assign_attributes(
            hub: s[:hub],
            stop_type: s[:stop_type],
            title: s[:title],
            address_label: s[:address_label],
            manifest_summary: s[:manifest_summary],
            handoff_note: s[:handoff_note],
            scheduled_window: s[:scheduled_window],
            confirmed_at: s[:confirmed_at],
            coordinates: Decidim::CommonNeed::ApplicationRecord.point_from_lat_lng(s[:lat], s[:lng]),
            state: s[:state]
          )
          stop.save!
        end

        # Second Partner Handoff Batch: BATCH-OAK-412 (Elena R.)
        delivery2 = Decidim::CommonNeed::Delivery.find_or_initialize_by(
          decidim_component_id: component.id,
          batch_code: "BATCH-OAK-412"
        )
        delivery2.assign_attributes(
          decidim_user_id: author.id,
          volunteer_user_id: author.id,
          shift_code: "SHIFT #OAK-412",
          route_title: "Elena R. (Volunteer Courier Route)",
          window_headline: "Pickup at 3:15 PM • Serving 7 neighborhood households in this loop",
          handoff_instructions: "Pull from Shelf: 6x Produce Bundles, 5x Sourdough Loaves, 3x Grain Boxes",
          dropoff_block_label: "Fruitvale & San Antonio Loop",
          dropoff_coordinates: Decidim::CommonNeed::ApplicationRecord.point_from_lat_lng(37.7756, -122.2241),
          total_duration_minutes: 55,
          total_distance_miles: 5.4,
          milestone_step: 1,
          crates_staged_at_ramp: false,
          state: "shift_claimed"
        )
        delivery2.save!
      end

      def seed_timebank_shifts!(component, author)
        shifts = [
          {
            shift_title: "Thu 2:00 PM • East Oakland Loop",
            pickup_address: "Pickup at 7800 MacArthur Blvd • 4 Households (4.6 mi)",
            households_count: 4,
            distance_miles: 4.6,
            transport_mode: "walking_bicycle_vehicle",
            hours_contributed: 2.0,
            node_code: "#OAK-01",
            state: "claimed"
          },
          {
            shift_title: "Sat 10:00 AM • Fruitvale & San Antonio Loop",
            pickup_address: "Pickup at 3301 E 12th St • 5 Households (2.1 mi)",
            households_count: 5,
            distance_miles: 2.1,
            transport_mode: "walking_bicycle_vehicle",
            hours_contributed: 2.5,
            node_code: "#OAK-01",
            state: "open"
          }
        ]

        shifts.each do |attrs|
          entry = Decidim::CommonNeed::TimebankEntry.find_or_initialize_by(
            decidim_component_id: component.id,
            shift_title: attrs[:shift_title]
          )
          entry.assign_attributes(attrs.merge(decidim_user_id: author.id))
          entry.save!
        end
      end

      def seed_partner_calendar_meetings!(component, author)
        return unless defined?(Decidim::Meetings::Meeting) && participatory_space && defined?(Decidim::Component)

        meetings_component = Decidim::Component.find_or_create_by!(
          participatory_space: participatory_space,
          manifest_name: "meetings"
        ) do |comp|
          comp.name = { "en" => "Local Area Partner Calendar (#OAK-01)" }
          comp.published_at = Time.current
        end

        PARTNER_CALENDAR_EVENTS_DATA.each do |ev|
          meeting = Decidim::Meetings::Meeting.find_or_initialize_by(
            component: meetings_component,
            address: ev[:address],
            start_time: ev[:start_time]
          )
          meeting.assign_attributes(
            author: author,
            title: { "en" => ev[:title] },
            description: { "en" => "#{ev[:description]} (#{ev[:accessibility_badge]})" },
            location: { "en" => ev[:host_line] },
            location_hints: { "en" => "#{ev[:day_label]} | #{ev[:org_key]} | #{ev[:topic_key]} | #{ev[:category_chip]}" },
            end_time: ev[:end_time],
            latitude: ev[:lat],
            longitude: ev[:lng],
            available_slots: ev[:available_slots],
            registrations_enabled: true,
            published_at: Time.current
          )
          meeting.save!
        end
      rescue StandardError
        # Fallback to PARTNER_CALENDAR_EVENTS_DATA when running outside a full Decidim Meetings schema
        nil
      end

      def seed_federated_nodes_and_requests!(component)
        nodes = [
          {
            node_code: "#OAK-01",
            name: "East Oakland Node",
            domain: "eastoakland.commonneed.org",
            deployment_mode: "Standalone Sovereign Docker",
            osrm_region: "Bay Area / NorCal OSRM",
            oauth_application_uid: "doorkeeper-oak-01-sovereign",
            active_hubs_count: 4,
            households_served_monthly: 312,
            shift_fill_rate_pct: 94.2,
            surplus_rescued_lbs: 1840,
            latency_ms: 18,
            household_pii_bytes_on_hub: 0,
            state: "healthy"
          },
          {
            node_code: "#BER-04",
            name: "Berkeley & North County Cooperative Node",
            domain: "berkeley.commonneed.org",
            deployment_mode: "Standalone Sovereign Docker",
            osrm_region: "Bay Area / NorCal OSRM",
            oauth_application_uid: "doorkeeper-ber-04-sovereign",
            active_hubs_count: 5,
            households_served_monthly: 380,
            shift_fill_rate_pct: 96.1,
            surplus_rescued_lbs: 2150,
            latency_ms: 21,
            household_pii_bytes_on_hub: 0,
            state: "healthy"
          },
          {
            node_code: "#RCH-03",
            name: "Richmond / West County Node",
            domain: "richmond.commonneed.org",
            deployment_mode: "Standalone Sovereign Docker",
            osrm_region: "Bay Area / NorCal OSRM",
            oauth_application_uid: "doorkeeper-rch-03-sovereign",
            active_hubs_count: 3,
            households_served_monthly: 275,
            shift_fill_rate_pct: 93.8,
            surplus_rescued_lbs: 1420,
            latency_ms: 24,
            household_pii_bytes_on_hub: 0,
            state: "healthy"
          }
        ]

        nodes.each do |n_attrs|
          node = Decidim::CommonNeed::FederatedNode.find_or_initialize_by(node_code: n_attrs[:node_code])
          node.assign_attributes(
            n_attrs.merge(
              decidim_component_id: component.id,
              last_synced_at: Time.current
            )
          )
          node.save!
        end

        req = Decidim::CommonNeed::InterNodeRequest.find_or_initialize_by(request_code: "REQ #401")
        req.assign_attributes(
          decidim_component_id: component.id,
          requesting_node_code: "#RCH-03",
          requesting_node_name: "Richmond / West County Node (#RCH-03)",
          source_node_codes: ["#OAK-01", "#BER-04"],
          request_type: "surplus",
          priority: "HIGH PRIORITY",
          need_summary: "Requesting 400 N95 Masks & 20 Staple Grain Boxes routed from neighboring East Oakland (#OAK-01) and Berkeley (#BER-04) surplus reserves.",
          state: "open"
        )
        req.save!
      end

      def seed_governance_proposals!(component, author)
        return unless defined?(Decidim::Proposals::Proposal) && participatory_space && defined?(Decidim::Component)

        proposals_component = Decidim::Component.find_or_create_by!(
          participatory_space: participatory_space,
          manifest_name: "proposals"
        ) do |comp|
          comp.name = { "en" => "Democratic Node & Network Governance (1 Member = 1 Vote)" }
          comp.published_at = Time.current
        end

        GOVERNANCE_PROPOSALS_DATA.each do |prop_data|
          proposal = Decidim::Proposals::Proposal.find_or_initialize_by(
            component: proposals_component,
            title: { "en" => prop_data[:title] }
          )
          proposal.assign_attributes(
            body: { "en" => prop_data[:body] },
            published_at: Time.current
          )
          proposal.add_coauthor(author) if proposal.respond_to?(:add_coauthor) && author && !author.is_a?(OpenStruct)
          proposal.save!
        end
      rescue StandardError
        # Fallback to GOVERNANCE_PROPOSALS_DATA when running outside a full Decidim Proposals schema
        nil
      end
    end
  end
end
