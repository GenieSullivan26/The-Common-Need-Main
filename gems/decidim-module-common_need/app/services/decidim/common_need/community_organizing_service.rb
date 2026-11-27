# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Powers the Partner PWA Community Organizing Hub:
    # 1. Step-by-step launch & democratic governance guides for new collectives
    # 2. Coalition & campaign-building logistics (timelines, role/turnout coordination,
    #    mutual-aid resource pooling, and cross-hub dispatches)
    # 3. High-effectiveness class formation & political/popular education (curriculum
    #    tracks, study circles, skill-shares, cohort scheduling, and leadership pipelines)
    class CommunityOrganizingService
      LAUNCH_GOVERNANCE_GUIDES = [
        {
          step: 1,
          slug: "listening_mapping",
          title: "Neighborhood Listening & Survival Needs Map",
          summary: "Conduct 1-on-1 porch/block conversations, map urgent unmet material needs, and convene a 5–7 neighbor anchor crew."
        },
        {
          step: 2,
          slug: "points_of_unity",
          title: "Points of Unity & Zero-Means-Testing Charter",
          summary: "Adopt unconditional solidarity principles (Solidarity, Not Charity), anti-gatekeeping intake norms, and language justice."
        },
        {
          step: 3,
          slug: "horizontal_governance",
          title: "Horizontal Assembly & Working-Group Governance (1 Member = 1 Vote)",
          summary: "Establish Decidim general assemblies, rotating facilitation, recallable stewards, and 2/3 democratic decision thresholds."
        },
        {
          step: 4,
          slug: "cooperative_treasury",
          title: "Cooperative Treasury, Fiscal Sponsorship & Open Ledger",
          summary: "Configure 501(c)(3) sponsorship or autonomous solidarity dues with dual-signer participatory budgeting on the Local Node."
        },
        {
          step: 5,
          slug: "hub_courier_setup",
          title: "Safe Hub Operations, De-Escalation & Courier Loop Setup",
          summary: "Stage accessible loading zones, non-carceral care protocols, and sync with Local Node OSRM volunteer courier shifts."
        },
        {
          step: 6,
          slug: "federated_peering",
          title: "Federated Node Peering & Quarterly Community Audits",
          summary: "Peer with neighboring hubs while retaining 100% local PII sovereignty (0 Bytes PII upstream) and run member audits."
        }
      ].freeze

      CURRICULUM_TRACKS = [
        {
          id: "track-mutual-aid",
          title: "Mutual Aid vs. Charity & Political Economy of the Neighborhood",
          sessions: 4,
          focus: "Why scarcity is engineered, autonomous survival pending transformation, and turning pantries into base-building hubs."
        },
        {
          id: "track-tenant-unions",
          title: "Tenant Unions, Land Trusts & Collective Bargaining",
          sessions: 4,
          focus: "Corporate landlord/LLC research, building-by-building committees, habitability escalations, and community land trusts."
        },
        {
          id: "track-worker-coops",
          title: "Worker Co-ops, Workplace Organizing & Solidarity Economics",
          sessions: 4,
          focus: "Democratic worker-ownership, wage-theft defense, labor-community coalitions, and federated cooperative supply chains."
        },
        {
          id: "track-abolitionist-care",
          title: "Participatory Democracy, Abolitionist Care & Community Safety",
          sessions: 3,
          focus: "Non-carceral crisis de-escalation, transformative conflict resolution, and facilitating 1 Member = 1 Vote assemblies."
        }
      ].freeze

      LEADERSHIP_PIPELINE_STAGES = [
        { stage: 1, name: "Neighbor & Mutual-Aid Participant", role_focus: "Unconditional care recipient welcomed into shared meals & open assemblies" },
        { stage: 2, name: "Study Circle & Shift Steward", role_focus: "Joins a popular-education cohort and co-anchors hub or courier shifts" },
        { stage: 3, name: "Working-Group Anchor & Facilitator", role_focus: "Co-leads clinics, tenant intakes, skill-shares, or coalition campaigns" },
        { stage: 4, name: "Recallable Collective Delegate & Mentor", role_focus: "Represents hub at federated council and mentors emerging stewards" }
      ].freeze

      CHARTER_MODELS = {
        "mutual_aid_hub" => {
          label: "Mutual-Aid Pantry & Care Collective",
          quorum: "25% active stewards (2/3 solidarity vote)",
          working_groups: %w(Nourishment Courier-Logistics Care-Defense Popular-Education)
        },
        "tenant_union" => {
          label: "Building / Neighborhood Tenant Union",
          quorum: "50%+1 of member households per building",
          working_groups: %w(Building-Captains Legal-Defense Rent-Strike-Fund Comms-Research)
        },
        "worker_coop" => {
          label: "Democratic Worker Cooperative",
          quorum: "60% of worker-owners (1 Worker = 1 Vote)",
          working_groups: %w(Operations Open-Book-Finance Member-Education Community-Solidarity)
        },
        "care_pod" => {
          label: "Block-Level Resilience & Care Pod",
          quorum: "Simple majority of block stewards",
          working_groups: %w(Elder-Disability-Check-In Street-Medicine Childcare-Share Emergency-Comms)
        }
      }.freeze

      def initialize(node_code: Decidim::CommonNeed.local_node_code)
        @node_code = node_code
      end

      def overview_bundle
        {
          node_code: @node_code,
          household_pii_bytes_exposed: 0,
          launch_guides: LAUNCH_GOVERNANCE_GUIDES,
          curriculum_tracks: CURRICULUM_TRACKS,
          leadership_pipeline_stages: LEADERSHIP_PIPELINE_STAGES,
          charter_models: CHARTER_MODELS.keys
        }
      end

      def generate_charter_starter(model_key, collective_name: "Neighborhood Solidarity Collective")
        tpl = CHARTER_MODELS.fetch(model_key.to_s, CHARTER_MODELS["mutual_aid_hub"])
        {
          collective_name: collective_name,
          model_label: tpl[:label],
          node_code: @node_code,
          governance_principle: "1 Member = 1 Vote • Zero Means-Testing",
          quorum_rule: tpl[:quorum],
          working_groups: tpl[:working_groups],
          charter_markdown: <<~CHARTER.strip
            # #{collective_name} (#{@node_code}) — Democratic Charter
            • Model: #{tpl[:label]}
            • Access Principle: 100% Unconditional Solidarity ($0, Zero Means-Testing)
            • Assembly Quorum & Threshold: #{tpl[:quorum]}
            • Core Working Groups: #{tpl[:working_groups].join(', ')}
            • Data Sovereignty: Local Node PostgreSQL (#{@node_code}) — 0 Bytes PII Shared Upstream
          CHARTER
        }
      end

      def schedule_popular_ed_cohort(title:, session_type: "Study Circle", day: "Sat Nov 7", location: "7800 MacArthur Blvd", sync_to_member_calendar: true)
        clean_title = title.to_s.strip
        clean_title = "Neighborhood Study Circle & Skill-Share" if clean_title.empty?
        {
          cohort_id: "cohort-#{SecureRandom.hex(4)}",
          title: clean_title,
          session_type: session_type,
          day: day,
          location: location,
          node_code: @node_code,
          synced_to_member_calendar: !!sync_to_member_calendar,
          zero_means_testing: true
        }
      end
    end
  end
end
