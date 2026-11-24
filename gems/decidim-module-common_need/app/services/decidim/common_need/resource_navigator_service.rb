# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Live-Catalog-Trained Resource Navigator & Expert Social Service Knowledge Base.
    # Dynamically indexes all active free goods, services, partner surplus items, and clinics
    # on the sovereign Decidim instance (`ServiceItem.in_stock` + live partner surplus feed)
    # and pairs them with trauma-informed, zero-means-testing social service navigation guidance.
    class ResourceNavigatorService
      STOP_WORDS = %w(
        a an and are as at be by can do find for free from get give have help how i in is it
        looking me my need near of on or our please right some tell that the there they this
        to today up us want what where who with you your
      ).freeze

      EXPERT_SOCIAL_SERVICE_DOMAINS = {
        food_nutrition: {
          domain_key: :food_nutrition,
          title: "Food Security, CalFresh (SNAP), WIC & Community Nourishment",
          categories: %w(food garden pets co_ops mutual_aid social_services),
          keywords: %w(
            food hungry groceries eat produce vegetable greens collards kale grain rice beans
            oats bread sourdough olive oil vegan gluten halal kosher seed garden compost
            pet dog cat kibble flea animal calfresh snap ebt wic meal pantry kitchen bok choy
          ),
          eligibility_and_rights: [
            "Zero Means-Testing on Common Need: All pantry produce boxes, staple grains, co-op loaves, garden kits, and pet kibble are 100% free with zero income, ID, or citizenship checks.",
            "3-Day Expedited CalFresh (Emergency SNAP): Households with <$150 monthly gross income and <$100 liquid cash (or monthly rent + utilities exceeding gross income) qualify by law for 3-day emergency EBT issuance.",
            "No Asset Limit & Public Charge Safe: CalFresh and WIC have no asset test for most households, include SSI/SSP seniors, and do NOT count under USCIS Public Charge rules."
          ],
          recommended_form: "Social Services: CalFresh / SNAP, Medi-Cal & LIHEAP Packet"
        },
        housing_eviction: {
          domain_key: :housing_eviction,
          title: "Housing Stability, Eviction Defense, Rent Relief & Utility Protection",
          categories: %w(housing legal_aid social_services),
          keywords: %w(
            housing rent eviction evicted landlord tenant lease notice unlawful detainer ud-105
            court summons lockout lock mold leak heat weatherization dehumidifier utility pge
            electric gas water shutoff arrears liheap unhoused shelter habitability
          ),
          eligibility_and_rights: [
            "Urgent 10-Business-Day Eviction Rule: If served an Unlawful Detainer court Summons & Complaint in California, you have 10 business days (excluding weekends/court holidays) to file an Answer (UD-105) to stop a default lockout.",
            "Illegal Lockouts & Shutoffs: A landlord cannot legally change locks, remove belongings, or shut off utilities without a court judgment and sheriff's writ. Keep all 3-day notices and repair photos.",
            "Emergency Rent & LIHEAP Utility Relief: Back-rent stabilization grants, tenant habitability repair kits, and LIHEAP / Medical Baseline utility shutoff protections can be filed simultaneously."
          ],
          recommended_form: "Legal Aid: Eviction Defense & Record Expungement Intake"
        },
        healthcare_mental_health: {
          domain_key: :healthcare_mental_health,
          title: "Healthcare, Full-Scope Medi-Cal, Medical Equipment & Peer Support",
          categories: %w(medical health mental_health public_safety),
          keywords: %w(
            health medical doctor clinic medi-cal insurance hospital walker wheelchair cane
            mobility blood pressure wound mask n95 air filter smoke immunocompromised mental
            counseling therapy trauma stress anxiety weighted blanket crisis narcan naloxone
            overdose harm reduction ihss caregiver disability senior
          ),
          eligibility_and_rights: [
            "Full-Scope Medi-Cal for All Ages: Income-eligible California residents of all ages qualify for full-scope Medi-Cal (medical, dental, vision, mental health) regardless of immigration status and with zero asset limit.",
            "IHSS & ADA Medical Equipment: Seniors and disabled neighbors on Medi-Cal can apply for In-Home Supportive Services (IHSS) to pay a family/chosen caregiver, while sanitized walkers, BP monitors, and N95s dispatch free today.",
            "Non-Carceral Crisis & Harm Reduction: Bilingual peer trauma counseling, somatic grounding kits, Narcan overdose reversal kits, and community night escorts operate with zero police involvement."
          ],
          recommended_form: "Social Services: CalFresh / SNAP, Medi-Cal & LIHEAP Packet"
        },
        veteran_benefits: {
          domain_key: :veteran_benefits,
          title: "Veterans VA Disability Claims, DD-214, PACT Act & Supportive Care",
          categories: %w(veteran_services housing social_services),
          keywords: %w(
            veteran veterans va military service dd-214 dd214 discharge disability claim vso
            pact burn pit ptsd hud-vash ssvf gi
          ),
          eligibility_and_rights: [
            "Lock In Back-Pay with Intent to File: Submitting VA Form 21-0966 (Intent to File) preserves your retroactive effective date for up to 1 year while we gather medical nexus letters and service records.",
            "$0 Accredited VSO Advocacy: By federal law, accredited Veteran Service Officers prepare and file initial VA disability claims, PACT Act toxic-exposure claims, and DD-214 requests completely free.",
            "Discharge Upgrades & Veteran Housing: Veterans with Other-Than-Honorable discharges due to PTSD/TBI/MST can petition for upgrades unlocking VA healthcare and SSVF / HUD-VASH housing vouchers."
          ],
          recommended_form: "Veteran Services: VA Disability Claim & DD-214 Support Packet"
        },
        immigration_civic_id: {
          domain_key: :immigration_civic_id,
          title: "Municipal City ID, Immigration Legal Aid, Public Charge & Transit Access",
          categories: %w(public_sector legal_aid),
          keywords: %w(
            id municipal card passport undocumented immigrant immigration asylum green card
            public charge citizenship transit bus bart clipper paratransit expungement record
          ),
          eligibility_and_rights: [
            "USCIS Public Charge Reassurance: Using Common Need hubs, food pantries, WIC, CalFresh, Municipal IDs, emergency rent relief, or community Medi-Cal does NOT count against green card / Public Charge determinations.",
            "Fee-Waived Municipal ID: Official City/Municipal ID cards accept foreign passports, consular IDs, and local residency proof with 100% fee waivers — valid for schools, clinics, libraries, and credit unions.",
            "Regional Transit & Paratransit: Clipper START provides 50% regional fare discounts, and East Bay ADA Paratransit offers door-to-door lift-equipped van transport."
          ],
          recommended_form: "Public Sector: Municipal ID & Paratransit Fee Waiver"
        },
        family_youth_education: {
          domain_key: :family_youth_education,
          title: "Children, Infants, Youth Support, Computers & Adult/Youth Education",
          categories: %w(youth_services education arts recreation),
          keywords: %w(
            baby infant diaper diapers wipes formula child children kids youth school backpack
            stem laptop computer linux internet ged esl english tutoring childcare calworks
            art paint screenprinting soccer basketball yoga park recreation
          ),
          eligibility_and_rights: [
            "Immediate Family & Infant Care: Size 1–5 diapers, infant formula, STEM school backpacks, refurbished Linux laptops, and art/recreation kits are available for immediate zero-cost courier delivery.",
            "CalWORKs & Subsidized Childcare: Families with children may qualify for CalWORKs cash aid, Stage 1 childcare vouchers, and county diaper stipends alongside WIC infant nutrition.",
            "McKinney-Vento Student Protections: Youth experiencing doubled-up or unstable housing have the federal right to immediate school enrollment without transcripts and free school transportation."
          ],
          recommended_form: "Social Services: CalFresh / SNAP, Medi-Cal & LIHEAP Packet"
        },
        employment_worker_rights: {
          domain_key: :employment_worker_rights,
          title: "Union Apprenticeships, Work Gear/PPE, Job Training & Worker Rights",
          categories: %w(employment education legal_aid),
          keywords: %w(
            job jobs work employment unemployed career union trade apprenticeship construction
            osha boots ppe hardhat resume wage theft unpaid overtime paycheck fired sdi ui
          ),
          eligibility_and_rights: [
            "No-Cost Union Entry & Safety Gear: Steel-toe work boots, high-vis vests, hardhats, OSHA-10 prep, and building-trades hiring hall referrals are provided at $0 so cost never blocks starting a job.",
            "Wage Theft & Workplace Rights: California Labor Commissioner wage-theft, unpaid overtime, and sick-leave claims protect ALL workers regardless of immigration Status or cash pay.",
            "WIOA Stipends & UI/SDI Navigation: Displaced workers can combine Unemployment Insurance (UI) or State Disability / Paid Family Leave (SDI/PFL) with WIOA paid training grants."
          ],
          recommended_form: "Legal Aid: Eviction Defense & Record Expungement Intake"
        }
      }.freeze

      @live_surplus_mutex = Mutex.new
      @registered_live_surplus = []

      class << self
        def register_live_surplus_item!(name:, stock_quantity: 20, category: "food", hub_name: "East Oakland Collective Pantry & Commons", tags: "Fresh Partner Surplus • Zero Means-Testing", node_code: Decidim::CommonNeed.local_node_code)
          item = {
            id: "surplus-#{SecureRandom.hex(4)}",
            title: name.to_s.strip,
            category: category.to_s,
            category_chip: "🆕 LIVE PARTNER SURPLUS",
            hub_title: hub_name.to_s,
            short_hub: hub_name.to_s.split(" ").first(3).join(" "),
            distance_miles: "1.2",
            tags_summary: tags.to_s,
            yield_summary: "Live Surplus: #{stock_quantity.to_i} shares posted just now • Ready for pickup/courier",
            stock_quantity: stock_quantity.to_i,
            action_type: :add_share,
            live_surplus: true,
            node_code: node_code.to_s,
            posted_at: Time.current.iso8601
          }
          @live_surplus_mutex.synchronize do
            @registered_live_surplus.unshift(item)
            @registered_live_surplus = @registered_live_surplus.first(30)
          end
          item
        end

        def registered_live_surplus_items(node_code: nil)
          @live_surplus_mutex.synchronize do
            return @registered_live_surplus.dup if node_code.blank?

            @registered_live_surplus.select { |i| i[:node_code].blank? || i[:node_code] == node_code.to_s }
          end
        end

        def clear_registered_live_surplus!
          @live_surplus_mutex.synchronize { @registered_live_surplus.clear }
        end
      end

      attr_reader :node_code, :endpoint

      def initialize(node_code: Decidim::CommonNeed.local_node_code, endpoint: Decidim::CommonNeed.local_ollama_endpoint)
        @node_code = node_code.presence || "#OAK-01"
        @endpoint = endpoint
        Decidim::CommonNeed::LocalAiPaperworkService.new(endpoint: @endpoint, node_code: @node_code).validate_local_endpoint!
      end

      # Returns the complete, real-time inventory of free goods & services currently listed on the instance
      def live_catalog_items(extra_surplus_items: [])
        items = []

        # 1. Include runtime partner surplus items passed from PWA client or registered on instance
        normalized_extra = Array(extra_surplus_items).filter_map { |raw| normalize_external_item(raw) }
        items.concat(normalized_extra)
        items.concat(self.class.registered_live_surplus_items(node_code: node_code))

        # 2. Include live ActiveRecord ServiceItems in stock on the Decidim instance
        items.concat(load_database_service_items)

        # 3. Merge baseline 19-category instance PWA catalog offerings (deduplicated by title)
        seen_titles = items.each_with_object(Set.new) { |i, s| s.add(i[:title].to_s.downcase) }
        baseline_instance_catalog_items.each do |base_item|
          key = base_item[:title].to_s.downcase
          next if seen_titles.include?(key)

          seen_titles.add(key)
          items << base_item
        end

        items
      end

      def live_calendar_events(extra_events: [])
        events = Array(extra_events).filter_map do |ev|
          next unless ev.is_a?(Hash)

          title = (ev[:title] || ev["title"]).to_s.strip
          next if title.blank?

          {
            title: title,
            date_time_badge: (ev[:date_time_badge] || ev["date_time_badge"] || ev[:dayLabel] || ev["dayLabel"] || "Upcoming Clinic").to_s,
            host_sub: (ev[:host_sub] || ev["host_sub"] || "Local Partner Hub • #{node_code}").to_s,
            description: (ev[:description] || ev["description"] || "Open community clinic & distribution with zero means-testing.").to_s,
            keywords: "#{title.downcase} #{(ev[:category_chip] || ev['catLabel']).to_s.downcase}"
          }
        end
        events + baseline_instance_events
      end

      def navigate(prompt_text, extra_surplus_items: [], extra_events: [])
        clean_prompt = prompt_text.to_s.strip
        catalog = live_catalog_items(extra_surplus_items: extra_surplus_items)
        events = live_calendar_events(extra_events: extra_events)

        tokens = tokenize(clean_prompt)
        lower = clean_prompt.downcase

        is_inventory_overview = lower.match?(/\b(what.*available|all.*free|everything|new surplus|what do you have|list all|updated|inventory|catalog)\b/)

        matched_domains = match_expert_domains(lower, tokens)
        matched_items = score_and_match_items(catalog, lower, tokens, matched_domains, overview: is_inventory_overview)
        matched_events = score_and_match_events(events, lower, tokens, matched_domains)

        matched_categories = matched_items.map { |i| i[:category] }.uniq
        recommended_forms = matched_domains.map { |d| d[:recommended_form] }.compact.uniq
        recommended_forms << Decidim::CommonNeed::MemberPortal::PAPERWORK_TEMPLATES.first if recommended_forms.empty?

        expert_tips = matched_domains.flat_map { |d| d[:eligibility_and_rights].first(2) }.uniq.first(3)
        if expert_tips.empty?
          expert_tips = EXPERT_SOCIAL_SERVICE_DOMAINS[:food_nutrition][:eligibility_and_rights].first(2)
        end

        {
          node_code: node_code,
          external_bytes_sent: 0,
          live_catalog_count: catalog.size,
          live_surplus_count: catalog.count { |i| i[:live_surplus] },
          matched_categories: matched_categories,
          matched_domains: matched_domains.map { |d| d[:domain_key] },
          matched_items: matched_items,
          matched_events: matched_events,
          expert_guidance: expert_tips,
          recommended_forms: recommended_forms,
          reply_html: render_reply_html(
            matched_items: matched_items,
            matched_events: matched_events,
            matched_domains: matched_domains,
            expert_tips: expert_tips,
            recommended_forms: recommended_forms,
            catalog_count: catalog.size,
            overview: is_inventory_overview
          )
        }
      end

      private

      def tokenize(text)
        text.to_s.downcase.scan(/[a-z0-9\-]+/).reject { |w| w.length < 2 || STOP_WORDS.include?(w) }.uniq
      end

      def match_expert_domains(lower, tokens)
        scored = EXPERT_SOCIAL_SERVICE_DOMAINS.values.map do |domain|
          score = 0
          domain[:keywords].each do |kw|
            if kw.include?(" ")
              score += 4 if lower.include?(kw)
            elsif tokens.include?(kw)
              score += 3
            elsif tokens.any? { |t| t.length >= 4 && (kw.start_with?(t) || t.start_with?(kw)) }
              score += 2
            end
          end
          [domain, score]
        end

        positive = scored.select { |_, s| s.positive? }.sort_by { |_, s| -s }.map(&:first)
        return positive.first(2) if positive.any?

        [EXPERT_SOCIAL_SERVICE_DOMAINS[:food_nutrition]]
      end

      def score_and_match_items(catalog, lower, tokens, matched_domains, overview: false)
        if overview
          surplus = catalog.select { |i| i[:live_surplus] }
          featured = catalog.reject { |i| i[:live_surplus] }.first(5)
          return (surplus + featured).first(7)
        end

        domain_cats = matched_domains.flat_map { |d| d[:categories] }.uniq

        scored = catalog.map do |item|
          haystack = [
            item[:title],
            item[:category],
            item[:category].to_s.tr("_", " "),
            item[:tags_summary],
            item[:yield_summary],
            item[:hub_title]
          ].join(" ").downcase

          score = 0
          tokens.each do |tok|
            if item[:title].to_s.downcase.include?(tok)
              score += 6
            elsif haystack.include?(tok)
              score += 3
            end
          end

          score += 2 if domain_cats.include?(item[:category].to_s)
          score += 2 if item[:live_surplus] && (lower.include?("surplus") || lower.include?("fresh") || lower.include?("food") || score.positive?)

          [item, score]
        end

        matched = scored.select { |_, s| s.positive? }.sort_by { |_, s| -s }.map(&:first)
        matched.any? ? matched.first(4) : catalog.first(4)
      end

      def score_and_match_events(events, _lower, tokens, matched_domains)
        domain_cats = matched_domains.flat_map { |d| d[:categories] }.uniq
        scored = events.map do |ev|
          haystack = "#{ev[:title]} #{ev[:description]} #{ev[:keywords]}".downcase
          score = 0
          tokens.each { |tok| score += 3 if haystack.include?(tok) }
          domain_cats.each { |cat| score += 1 if haystack.include?(cat.tr("_", " ")) }
          [ev, score]
        end

        scored.select { |_, s| s >= 2 }.sort_by { |_, s| -s }.map(&:first).first(2)
      end

      def render_reply_html(matched_items:, matched_events:, matched_domains:, expert_tips:, recommended_forms:, catalog_count:, overview: false)
        domain_heading = if overview
                           "Live Free Goods, Surplus & Services Index (#{catalog_count} Active on #{node_code})"
                         else
                           matched_domains.map { |d| d[:title] }.join(" + ")
                         end

        items_html = matched_items.map do |item|
          surplus_badge = item[:live_surplus] ? '<span style="color:#120924; background:var(--lime-bright); padding:1px 5px; border-radius:4px; font-size:9.5px; font-weight:800; margin-right:4px;">LIVE SURPLUS</span>' : ""
          "• #{surplus_badge}<strong>#{escape_html(item[:title])}</strong> — #{escape_html(item[:hub_title])} (#{escape_html(item[:yield_summary])})"
        end.join("<br>")

        tips_html = expert_tips.map do |tip|
          "• #{escape_html(tip)}"
        end.join("<br>")

        events_html = if matched_events.any?
                        ev_lines = matched_events.map { |ev| "• <strong>#{escape_html(ev[:title])}</strong> (#{escape_html(ev[:date_time_badge])})" }.join("<br>")
                        "<div style=\"margin-top:8px;\"><strong>📅 Matching Local Clinics & Pop-Ups:</strong><br>#{ev_lines}</div>"
                      else
                        ""
                      end

        <<~HTML.strip
          <div><strong>#{escape_html(domain_heading)}</strong></div>
          <div style="margin-top:6px;"><strong>📦 Live Free Goods & Services Matched on #{escape_html(node_code)}:</strong><br>#{items_html}</div>
          <div style="margin-top:8px;"><strong>🧭 Resource Navigation & Eligibility Guidance:</strong><br>#{tips_html}</div>
          #{events_html}
          <div style="margin-top:6px; font-size:11px; opacity:0.88;">Recommended Encrypted Form: <strong>#{escape_html(recommended_forms.first)}</strong></div>
        HTML
      end

      def normalize_external_item(raw)
        return nil unless raw.is_a?(Hash)

        title = (raw[:title] || raw["title"] || raw[:name] || raw["name"]).to_s.strip
        return nil if title.blank?

        qty = (raw[:stock_quantity] || raw["stock_quantity"] || raw[:qty] || raw["qty"] || 20).to_i
        hub_title = (raw[:hub_title] || raw["hub_title"] || raw[:hub] || raw["hub"] || "East Oakland Collective Pantry & Commons").to_s
        {
          title: title,
          category: (raw[:category] || raw["category"] || "food").to_s,
          category_chip: "🆕 LIVE PARTNER SURPLUS",
          hub_title: hub_title,
          short_hub: hub_title.split(" ").first(3).join(" "),
          distance_miles: (raw[:distance_miles] || raw["distance_miles"] || "1.2").to_s,
          tags_summary: (raw[:tags_summary] || raw["tags_summary"] || raw[:tags] || raw["tags"] || "Fresh Partner Surplus • Zero Means-Testing").to_s,
          yield_summary: (raw[:yield_summary] || raw["yield_summary"] || "Live Surplus: #{qty} left on #{node_code}").to_s,
          stock_quantity: qty,
          action_type: :add_share,
          live_surplus: raw.key?(:live_surplus) ? !!raw[:live_surplus] : (raw.key?("live_surplus") ? !!raw["live_surplus"] : true)
        }
      end

      def load_database_service_items
        return [] unless defined?(Decidim::Services::ServiceItem) && Decidim::Services::ServiceItem.respond_to?(:in_stock)

        records = Array(Decidim::Services::ServiceItem.in_stock)
        records.filter_map do |rec|
          title = rec.respond_to?(:title) ? rec.title.to_s : ""
          next if title.blank?

          hub_name = if rec.respond_to?(:hub) && rec.hub.respond_to?(:title_text) && rec.hub.title_text.present?
                       rec.hub.title_text
                     else
                       "Local Node Verified Partner Hub"
                     end
          {
            title: title,
            category: rec.respond_to?(:category_key) ? rec.category_key.to_s : "mutual_aid",
            category_chip: rec.respond_to?(:category_key) ? rec.category_key.to_s.upcase.tr("_", " ") : "COMMUNITY SHARE",
            hub_title: hub_name,
            short_hub: hub_name.split(" ").first(3).join(" "),
            distance_miles: "1.0",
            tags_summary: rec.respond_to?(:dietary_and_safety_tags) ? rec.dietary_and_safety_tags.to_s : "Zero Means-Testing",
            yield_summary: rec.respond_to?(:yield_summary) && rec.yield_summary.present? ? rec.yield_summary.to_s : "#{rec.stock_quantity} in stock on #{node_code}",
            stock_quantity: rec.respond_to?(:stock_quantity) ? rec.stock_quantity.to_i : 10,
            action_type: rec.respond_to?(:paperwork_mode?) && rec.paperwork_mode? ? :ai_paperwork : :add_share,
            live_surplus: true
          }
        end
      rescue StandardError
        []
      end

      def baseline_instance_catalog_items
        ctrl = Decidim::CommonNeed::PwaPortalController.new
        ctrl.index
        hubs = ctrl.instance_variable_get(:@hubs) || []
        hubs.flat_map do |hub|
          (hub[:items] || []).map do |item|
            {
              title: item[:title],
              category: item[:category],
              category_chip: item[:category_chip],
              hub_title: hub[:title],
              short_hub: hub[:short_name],
              distance_miles: hub[:distance_miles],
              tags_summary: item[:tags_summary],
              yield_summary: item[:yield_summary],
              stock_quantity: 20,
              action_type: item[:action_type],
              paperwork_template: item[:paperwork_template],
              basket_item_name: item[:basket_item_name] || item[:title],
              live_surplus: false
            }
          end
        end
      end

      def baseline_instance_events
        ctrl = Decidim::CommonNeed::PwaPortalController.new
        ctrl.index
        events = ctrl.instance_variable_get(:@calendar_events) || []
        events.map do |ev|
          {
            title: ev[:title],
            date_time_badge: ev[:date_time_badge],
            host_sub: ev[:host_sub],
            description: ev[:description],
            keywords: ev[:keywords]
          }
        end
      end

      def escape_html(str)
        str.to_s
           .gsub("&", "&amp;")
           .gsub("<", "&lt;")
           .gsub(">", "&gt;")
           .gsub('"', "&quot;")
      end
    end
  end
end
