# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Renders the unified 5-Role PWA suite (`MemberPortal`, `VolunteerPortal`,
    # `PartnerPortal`, `LocalNodeAdmin`, `FederationHub`) using Trailblazer Cells,
    # Hotwire Turbo Frames/Streams, and Stimulus controllers.
    class PwaPortalController < ApplicationController
      layout false

      ROLE_ALIASES = {
        "member" => "member",
        "volunteer" => "volunteer",
        "partner" => "nonprofit",
        "nonprofit" => "nonprofit",
        "local_node" => "localnode",
        "localnode" => "localnode",
        "node_admin" => "localnode",
        "federation" => "network",
        "network" => "network"
      }.freeze

      def index
        resolved_role = ROLE_ALIASES[params[:role].to_s.downcase]
        @unified_suite = resolved_role.nil?
        @active_role = resolved_role || "member"
        @hubs = default_member_hubs
        @delivery_banner_state = default_delivery_banner_state
        @calendar_events = default_calendar_events
        @route_stops = default_volunteer_route_stops
        @paperwork_templates = Decidim::CommonNeed::MemberPortal::PAPERWORK_TEMPLATES
      end

      private

      def default_member_hubs
        [
          {
            badge_label: "NO MEANS-TESTING",
            member_audit_score: "4.9",
            title: "East Oakland Collective Pantry & Commons",
            short_name: "East Oakland Hub",
            categories_summary: "Food, Mutual Aid, Co-ops, Urban Garden & Pet Care",
            distance_miles: "1.2",
            items: [
              {
                category: "food",
                category_chip: "🍎 FOOD",
                title: "Organic Collard Greens, Kale & 25lb Staple Grain Box",
                tags_summary: "Vegan / GF / Halal • Fresh Greens + Rice, Pinto Beans & Oats",
                yield_summary: "Yield: ~39 Nourishing Family Meals (28 lbs) • High Stock",
                action_type: :stepper,
                stepper_key: "collards",
                initial_qty: 1
              },
              {
                category: "mutual_aid",
                category_chip: "🤝 MUTUAL AID",
                title: "Neighborhood Solidarity Hygiene, First-Aid & Power Outage Kit",
                tags_summary: "Community-Packed Mutual Aid Tote • Solar Lantern & Battery Bank",
                yield_summary: "Yield: Household Resilience & Neighbor Check-In Kit • Available",
                action_type: :add_share,
                button_label: "+ Add Share",
                basket_item_name: "Mutual Aid Solidarity & Lantern Kit",
                basket_hub_label: "Mutual Aid • East Oakland Hub"
              },
              {
                category: "co_ops",
                category_chip: "🌻 CO-OPS",
                title: "Worker Co-op Sourdough Loaves, Olive Oil & Bulk Roast Share",
                tags_summary: "East Bay Cooperative Network • Baked & Packed by Worker-Owners",
                yield_summary: "Yield: 2 Whole Wheat Loaves + 16oz Olive Oil • Cooperative Surplus",
                action_type: :add_share,
                button_label: "+ Add Share",
                basket_item_name: "Worker Co-op Sourdough & Olive Oil Share",
                basket_hub_label: "Co-ops • East Oakland Hub"
              },
              {
                category: "garden",
                category_chip: "🌱 GARDEN",
                title: "Urban Garden Seed Kit, 12 Vegetable Starts & Organic Compost",
                tags_summary: "Heirloom Tomatoes, Collards, Cilantro & 20lb Soil Amendments",
                yield_summary: "Yield: Home/Community Plot Food Sovereignty Kit • Available",
                action_type: :add_share,
                button_label: "+ Add Share",
                basket_item_name: "Urban Garden Starts & Compost Kit",
                basket_hub_label: "Garden • East Oakland Hub"
              },
              {
                category: "pets",
                category_chip: "🐾 PETS",
                title: "Companion Animal Kibble (20lb Dog/Cat), Flea Care & Leash Kit",
                tags_summary: "Grain-Free Kibble + Wet Food + Topical Flea Prevention",
                yield_summary: "Yield: 3-Week Companion Pet Nutrition & Care Supply",
                action_type: :add_share,
                button_label: "+ Add Share",
                basket_item_name: "20lb Pet Kibble & Flea Care Pack",
                basket_hub_label: "Pets • East Oakland Hub"
              }
            ]
          },
          {
            badge_label: "IMMUNOCOMPROMISED PRIORITY",
            member_audit_score: "5.0",
            title: "West County Health, Medical & Crisis Sanctuary",
            short_name: "West County Hub",
            categories_summary: "Health, Medical Equipment, Mental Health & Public Safety",
            distance_miles: "2.4",
            items: [
              {
                category: "health",
                category_chip: "😷 HEALTH",
                title: "N95 Particulate Respirator Masks (20-Pack) & MERV-13 Air Filter",
                tags_summary: "NIOSH Approved Respirators + Clean Air Box Fan Filter",
                yield_summary: "Yield: Household Respiratory & Smoke Defense • High Stock",
                action_type: :stepper,
                stepper_key: "masks",
                initial_qty: 1
              },
              {
                category: "medical",
                category_chip: "🩺 MEDICAL",
                title: "Folding Mobility Walker, Blood Pressure Cuff & Wound Care Kit",
                tags_summary: "ADA Durable Medical Equipment + Home Clinical Diagnostics",
                yield_summary: "Yield: Home Medical Recovery & Mobility Support • Sanitized",
                action_type: :add_share,
                button_label: "+ Request Item",
                basket_item_name: "Medical Mobility Walker & BP Monitor",
                basket_hub_label: "Medical • West County Hub"
              },
              {
                category: "mental_health",
                category_chip: "🧠 MENTAL HEALTH",
                title: "Bilingual Peer Trauma Counseling & Somatic Grounding Care Kit",
                tags_summary: "Confidential 1-on-1 Therapist/Peer Session + Weighted Blanket",
                yield_summary: "Yield: Non-Carceral Emotional Support & Stress Relief Delivery",
                action_type: :add_share,
                button_label: "+ Book & Deliver",
                basket_item_name: "Mental Health Counseling & Grounding Kit",
                basket_hub_label: "Mental health • West County Hub"
              },
              {
                category: "public_safety",
                category_chip: "🛟 PUBLIC SAFETY",
                title: "Narcan Overdose Reversal (2-Pack), Fire Blanket & Night Escort",
                tags_summary: "Community Harm Reduction + Senior/Shift-Worker Accompaniment",
                yield_summary: "Yield: Neighborhood Life-Safety & Non-Police De-Escalation",
                action_type: :add_share,
                button_label: "+ Add Safety Kit",
                basket_item_name: "Public Safety Narcan & Fire Blanket Kit",
                basket_hub_label: "Public safety • West County Hub"
              }
            ]
          },
          {
            badge_label: "ADVOCACY & PAPERWORK",
            member_audit_score: "4.95",
            title: "Fruitvale Legal, Housing, Veterans & Civic Resource Hub",
            short_name: "Fruitvale Hub",
            categories_summary: "Legal Aid, Housing, Social Services, Public Sector & Veterans",
            distance_miles: "1.5",
            items: [
              {
                category: "legal_aid",
                category_chip: "⚖️ LEGAL AID",
                title: "Eviction Defense, Record Expungement & Immigration Legal Clinic",
                tags_summary: "Unlawful Detainer Answer + Wage Theft & Asylum Legal Aid",
                yield_summary: "Yield: Licensed Legal Representation + Courier Court Filing",
                action_type: :ai_paperwork,
                button_label: "🧭 Start Legal",
                paperwork_template: "Legal Aid Eviction Defense & Expungement Intake"
              },
              {
                category: "housing",
                category_chip: "🏠 HOUSING",
                title: "Emergency Rent Relief Application & Home Weatherization/Mold Kit",
                tags_summary: "Tenant Habitability Repair Kit + Back-Rent Stabilization Grant",
                yield_summary: "Yield: Eviction Prevention + Delivered Dehumidifier/Draft Seals",
                action_type: :ai_paperwork,
                button_label: "🧭 Housing Help",
                paperwork_template: "Housing Rent Relief & Habitability Packet"
              },
              {
                category: "social_services",
                category_chip: "📋 SOCIAL SERVICES",
                title: "CalFresh / SNAP, Medi-Cal, WIC & LIHEAP Utility Arrears Filing",
                tags_summary: "Resource Navigator Auto-Fill + Bilingual Caseworker Verification",
                yield_summary: "Yield: 3-Day Expedited Benefits + Courier Printed Form Delivery",
                action_type: :ai_paperwork,
                button_label: "🧭 Auto-Fill",
                paperwork_template: "Social Services CalFresh, Medi-Cal & LIHEAP Packet"
              },
              {
                category: "public_sector",
                category_chip: "🏛️ PUBLIC SECTOR",
                title: "Municipal City ID, Clipper START Transit & Paratransit Enrollment",
                tags_summary: "City/County Fee-Waiver Vouchers + East Bay Paratransit Setup",
                yield_summary: "Yield: Official Municipal ID + No-Cost Regional Transit Access",
                action_type: :ai_paperwork,
                button_label: "🧭 Enroll Now",
                paperwork_template: "Public Sector Municipal ID & Paratransit Waiver"
              },
              {
                category: "veteran_services",
                category_chip: "🎖️ VETERAN SERVICES",
                title: "Veterans VA Disability Claim Filing, DD-214 & Supportive Care Pack",
                tags_summary: "Accredited Veteran Peer Advocate + Cold-Weather & Pantry Bundle",
                yield_summary: "Yield: VA Benefits Navigation + Home-Delivered Veteran Care Tote",
                action_type: :ai_paperwork,
                button_label: "🧭 VA Support",
                paperwork_template: "Veteran Services VA Claim & DD-214 Support Packet"
              }
            ]
          },
          {
            badge_label: "CULTURE, YOUTH & JOBS",
            member_audit_score: "4.92",
            title: "San Antonio Arts, Youth, Education & Worker Center",
            short_name: "San Antonio Center",
            categories_summary: "Employment, Education, Youth Services, Arts & Recreation",
            distance_miles: "1.8",
            items: [
              {
                category: "employment",
                category_chip: "🛠️ EMPLOYMENT",
                title: "Union Apprenticeship Prep, OSHA-10 Work Boots/PPE & Resume Clinic",
                tags_summary: "Steel-Toe Boots, High-Vis Vest, Hardhat + Hiring Hall Referral",
                yield_summary: "Yield: Job-Site Safety Gear Delivered + Union Career Placement",
                action_type: :add_share,
                button_label: "+ Add Work Kit",
                basket_item_name: "Employment Work Boots/PPE & Apprenticeship Pack",
                basket_hub_label: "Employment • Worker Center"
              },
              {
                category: "education",
                category_chip: "📚 EDUCATION",
                title: "Refurbished Linux Laptop, ESL/GED Study Books & Tutoring Pass",
                tags_summary: "LibreOffice + Offline Kiwix Wikipedia + Bilingual Adult/Youth Prep",
                yield_summary: "Yield: Permanent Household Computer + Weekly Study Support",
                action_type: :add_share,
                button_label: "+ Request Kit",
                basket_item_name: "Education Refurbished Laptop & GED/ESL Kit",
                basket_hub_label: "Education • San Antonio Center"
              },
              {
                category: "youth_services",
                category_chip: "🎒 YOUTH SERVICES",
                title: "Youth STEM Backpack, Infant Diapers/Formula & After-School Pass",
                tags_summary: "Size 1–5 Diapers + Formula + K-12 School Supplies & Mentorship",
                yield_summary: "Yield: Complete Early Childhood & Youth Development Bundle",
                action_type: :add_share,
                button_label: "+ Add Youth Pack",
                basket_item_name: "Youth STEM Backpack & Infant Diaper Bundle",
                basket_hub_label: "Youth services • San Antonio Center"
              },
              {
                category: "arts",
                category_chip: "🎨 ARTS",
                title: "Community Screenprinting, Acrylic Paint & Muralist Supply Box",
                tags_summary: "24-Color Acrylics, Heavyweight Sketchbooks, Brushes & Linocut Kit",
                yield_summary: "Yield: Home Studio Art Kit + Open Printmaking Workshop Access",
                action_type: :add_share,
                button_label: "+ Add Art Box",
                basket_item_name: "Arts Screenprinting & Painting Studio Box",
                basket_hub_label: "Arts • San Antonio Center"
              },
              {
                category: "recreation",
                category_chip: "⚽ RECREATION",
                title: "Neighborhood Soccer/Basketball Gear, Yoga Mat & Regional Park Pass",
                tags_summary: "Size 5 Soccer Ball, Pump, Non-Slip Yoga Mat & Swim/Park Vouchers",
                yield_summary: "Yield: Family Outdoor Recreation & Movement Equipment",
                action_type: :add_share,
                button_label: "+ Add Rec Kit",
                basket_item_name: "Recreation Soccer, Yoga & Park Pass Kit",
                basket_hub_label: "Recreation • San Antonio Center"
              }
            ]
          }
        ]
      end

      def default_delivery_banner_state
        {
          shift_code: "SHIFT #OAK-409",
          narrowed: false,
          expanded: false,
          handoff_note: "Handoff: Walk up 4 porch steps & wait 60s"
        }
      end

      def default_calendar_events
        [
          {
            day: "Tue Nov 3",
            org: "east_oakland",
            topic: "food",
            lat: "37.7651",
            lng: "-122.1755",
            location: "7800 MacArthur Blvd",
            keywords: "food garden seed swap hot meal dinner east oakland collective pantry",
            category_chip: "🍎 FOOD & 🌱 GARDEN",
            date_time_badge: "Tue Nov 3 • 4:00 PM – 7:00 PM",
            title: "Community Harvest Dinner & Winter Seed/Compost Swap",
            host_sub: "Hosted by: East Oakland Collective Pantry • 📍 7800 MacArthur Blvd (1.2 mi)",
            description: "Hot plantain & black bean dinner served to all neighbors, plus winter brassica seedlings, soil testing, and take-home produce boxes.",
            accessibility_badge: "✓ Childcare Space • ✓ ADA Ramp • 42 / 80 Spots Registered",
            rsvp_label: "+ RSVP on Local Node",
            rsvp_title: "Community Harvest Dinner & Seed Swap",
            secondary_action_type: :delivery_box,
            secondary_label: "🚚 Request Event Box Delivery",
            secondary_payload_title: "Harvest Dinner & Seed Swap Home Delivery Box",
            secondary_hub_label: "Calendar Event • East Oakland Hub"
          },
          {
            day: "Thu Nov 5",
            org: "fruitvale",
            topic: "legal",
            lat: "37.7756",
            lng: "-122.2241",
            location: "3301 E 12th St",
            keywords: "legal aid housing eviction defense calfresh social services veteran clinic fruitvale",
            category_chip: "⚖️ LEGAL AID • 🏠 HOUSING • 🎖️ VETERANS",
            date_time_badge: "Thu Nov 5 • 1:00 PM – 5:00 PM",
            title: "Tenant Eviction Defense, CalFresh & Veterans VA Claim Clinic",
            host_sub: "Hosted by: Fruitvale Legal & Civic Hub • 📍 3301 E 12th St / Hybrid (1.5 mi)",
            description: "1-on-1 licensed housing attorneys, accredited VA disability representatives, and bilingual CalFresh/Medi-Cal/LIHEAP enrollment navigators.",
            accessibility_badge: "✓ Español / Mam / Vietnamese Interpretation • 19 / 40 Slots Open",
            rsvp_label: "+ Reserve Clinic Slot",
            rsvp_title: "Tenant Legal, CalFresh & VA Clinic",
            secondary_action_type: :ai_paperwork,
            secondary_label: "🧭 Pre-Fill Clinic Forms",
            secondary_payload_title: "Legal Aid Eviction Defense & Expungement Intake"
          },
          {
            day: "Sat Nov 7",
            org: "west_county",
            topic: "health",
            lat: "37.8215",
            lng: "-122.2769",
            location: "3115 San Pablo Ave",
            keywords: "health medical mental health public safety narcan blood pressure walker clinic west county",
            category_chip: "🩺 MEDICAL • 🧠 MENTAL HEALTH • 🛟 SAFETY",
            date_time_badge: "Sat Nov 7 • 10:00 AM – 2:00 PM",
            title: "Street Medicine, Mobility Walker Fitting & Narcan Harm-Reduction Fair",
            host_sub: "Hosted by: West County Health Sanctuary • 📍 3115 San Pablo Ave (2.4 mi)",
            description: "No-cost blood pressure & glucose screenings, custom ADA walker/cane fittings, somatic trauma healing circles, and N95 + Narcan distribution.",
            accessibility_badge: "✓ Outdoor / HEPA Filtered • ✓ Fragrance-Free Zone • Open Walk-In",
            rsvp_label: "+ RSVP on Local Node",
            rsvp_title: "Street Medicine & Mobility Fitting Fair",
            secondary_action_type: :delivery_box,
            secondary_label: "🚚 Deliver Care Kit Home",
            secondary_payload_title: "Medical Mobility & Harm-Reduction Care Pack",
            secondary_hub_label: "Calendar Event • West County Sanctuary"
          },
          {
            day: "Sat Nov 7",
            org: "san_antonio",
            topic: "youth",
            lat: "37.7854",
            lng: "-122.2385",
            location: "2200 Foothill Blvd",
            keywords: "arts youth services education employment union apprenticeship screenprinting laptop san antonio",
            category_chip: "🎨 ARTS • 🎒 YOUTH • 🛠️ EMPLOYMENT • 📚 EDUCATION",
            date_time_badge: "Sat Nov 7 • 1:00 PM – 5:00 PM",
            title: "Union Apprenticeship Expo, Linux Laptop Lab & Youth Screenprinting Jam",
            host_sub: "Hosted by: San Antonio Worker & Youth Center • 📍 2200 Foothill Blvd (1.8 mi)",
            description: "Meet union building trades coordinators, pick up OSHA-10 work boots, get a refurbished Linux laptop configured, and join the youth poster workshop.",
            accessibility_badge: "✓ Youth Childcare & Playroom • ✓ Certificate of Attendance",
            rsvp_label: "+ RSVP on Local Node",
            rsvp_title: "Union Expo, Laptop Lab & Youth Arts Jam",
            secondary_action_type: :delivery_box,
            secondary_label: "🚚 Request Kit Delivery",
            secondary_payload_title: "Apprenticeship PPE & Youth Art Kit",
            secondary_hub_label: "Calendar Event • San Antonio Center"
          },
          {
            day: "Sun Nov 8",
            org: "east_oakland",
            topic: "food",
            lat: "37.7582",
            lng: "-122.1795",
            location: "Arroyo Viejo Park",
            keywords: "pets recreation mutual aid co-ops vet clinic dog cat kibble soccer park east oakland",
            category_chip: "🐾 PETS • ⚽ RECREATION • 🌻 CO-OPS",
            date_time_badge: "Sun Nov 8 • 11:00 AM – 3:00 PM",
            title: "Mobile Street Vet Clinic, Neighborhood Soccer & Worker Co-op Bake Share",
            host_sub: "Hosted by: East Oakland Commons & Co-op Network • 📍 Arroyo Viejo Park (0.9 mi)",
            description: "No-cost dog/cat vaccinations, microchipping, and 20lb kibble bags alongside all-ages pickup soccer, yoga in the park, and worker co-op sourdough bread.",
            accessibility_badge: "✓ Leash & Carrier Provided • ✓ All Ages Welcome",
            rsvp_label: "+ RSVP on Local Node",
            rsvp_title: "Mobile Street Vet & Park Recreation Day",
            secondary_action_type: :delivery_box,
            secondary_label: "🚚 Deliver Pet & Bread Kit",
            secondary_payload_title: "20lb Pet Kibble & Co-op Sourdough Share",
            secondary_hub_label: "Calendar Event • Arroyo Viejo Park"
          },
          {
            day: "Sun Nov 8",
            org: "fruitvale",
            topic: "legal",
            lat: "37.7749",
            lng: "-122.2248",
            location: "Fruitvale Plaza",
            keywords: "public sector social services city id clipper transit paratransit fruitvale",
            category_chip: "🏛️ PUBLIC SECTOR • 📋 SOCIAL SERVICES",
            date_time_badge: "Sun Nov 8 • 12:00 PM – 4:00 PM",
            title: "Mobile Municipal ID Card Printer & Clipper START / Paratransit Sign-Up",
            host_sub: "Hosted by: Fruitvale Civic Hub • 📍 Fruitvale Plaza (1.5 mi)",
            description: "On-the-spot photo and printing for official Oakland Municipal ID cards (fee waived) and instant activation of regional transit passes.",
            accessibility_badge: "✓ Same-Day Card Printing • ✓ Wheelchair Accessible Plaza",
            rsvp_label: "+ RSVP on Local Node",
            rsvp_title: "Mobile Municipal ID & Transit Enrollment",
            secondary_action_type: :ai_paperwork,
            secondary_label: "🧭 Prepare ID Waiver",
            secondary_payload_title: "Public Sector Municipal ID & Paratransit Waiver"
          }
        ]
      end

      def default_volunteer_route_stops
        [
          {
            stop_number: 1,
            stop_type: :pickup,
            confirmed: true,
            confirmed_badge_text: "✓ Confirmed 2:12 PM",
            title: "East Oakland Collective Pantry",
            subtitle: "7800 MacArthur Blvd • 4 Crates Loaded"
          },
          {
            stop_number: 2,
            stop_type: :pickup,
            confirmed: false,
            button_label: "✓ Confirm Pickup",
            title: "West County Mutual Aid Care Hub",
            subtitle: "3115 San Pablo Ave (By 2:30 PM)",
            parcel_summary: "📦 2 sealed medical/hygiene parcels (N95 Masks & Care Kits)",
            window_recalc_note: "📝 Confirming pickup recalculates and narrows Stop #3's arrival window."
          },
          {
            stop_number: 3,
            stop_type: :dropoff,
            confirmed: false,
            button_label: "✓ Confirm Delivery",
            title: "Member Household • 1400 Block of 62nd Ave",
            subtitle: "Handoff: Walk up 4 porch steps & wait 60s at door"
          }
        ]
      end
    end
  end
end
