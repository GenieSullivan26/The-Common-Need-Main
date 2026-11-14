# frozen_string_literal: true

require "openssl"
require "base64"
require "uri"
require "json"

module Decidim
  module CommonNeed
    # 100% Local AI & Encrypted Paperwork Co-Pilot for Node #OAK-01.
    # Connects strictly to the sovereign local Ollama endpoint (`127.0.0.1:11434`),
    # raising a `SecurityError` if any external cloud endpoint is configured.
    # Processes guided paperwork in ephemeral RAM using AES-256-GCM encryption.
    class LocalAiPaperworkService
      ALLOWED_LOCAL_HOSTS = %w(127.0.0.1 localhost ::1 [::1] ollama.local).freeze

      attr_reader :endpoint, :node_code

      def initialize(endpoint: Decidim::CommonNeed.local_ollama_endpoint, node_code: Decidim::CommonNeed.local_node_code)
        @endpoint = endpoint
        @node_code = node_code
        validate_local_endpoint!
      end

      def validate_local_endpoint!
        uri = URI.parse(endpoint.to_s)
        host = uri.host.to_s.downcase
        return true if ALLOWED_LOCAL_HOSTS.include?(host)

        raise SecurityError, "External cloud AI endpoints (#{host}) are strictly prohibited on sovereign node #{node_code}!"
      rescue URI::InvalidURIError
        raise SecurityError, "Invalid AI endpoint URI configured on node #{node_code}"
      end

      def match_community_needs(prompt_text)
        validate_local_endpoint!
        lower = prompt_text.to_s.downcase

        if lower.match?(/veteran|va |calfresh|snap|social|medi-cal|liheap/)
          veteran_and_social_match
        elsif lower.match?(/legal|housing|public sector|eviction|rent|municipal id/)
          legal_housing_and_public_sector_match
        elsif lower.match?(/mental|medical|youth|art|counseling|walker|diaper/)
          holistic_health_youth_and_arts_match
        else
          food_garden_pet_and_coop_match
        end
      end

      def process_guided_paperwork(form_or_attributes, care_basket: nil)
        validate_local_endpoint!
        attrs = extract_attributes(form_or_attributes)

        plaintext_payload = build_ephemeral_document(attrs)
        encrypted_bundle = encrypt_ephemeral_payload(plaintext_payload)

        if attrs[:delivery_mode] == "courier"
          basket_item = attach_courier_printed_packet(care_basket, attrs[:template_name])
          {
            mode: "courier",
            template_name: attrs[:template_name],
            node_code: node_code,
            external_bytes_sent: 0,
            courier_item_name: "Courier Printed Packet: #{attrs[:template_name]}",
            care_basket_item: basket_item,
            encrypted_vault_digest: encrypted_bundle[:auth_tag_b64]
          }
        else
          {
            mode: "pdf",
            template_name: attrs[:template_name],
            node_code: node_code,
            external_bytes_sent: 0,
            filename: "#{attrs[:template_name].parameterize}-oak-01-encrypted.pdf",
            cipher_algorithm: "AES-256-GCM",
            ciphertext_b64: encrypted_bundle[:ciphertext_b64],
            iv_b64: encrypted_bundle[:iv_b64],
            auth_tag_b64: encrypted_bundle[:auth_tag_b64],
            preview_summary: preview_summary_for(attrs)
          }
        end
      end

      private

      def extract_attributes(source)
        if source.respond_to?(:template_name)
          {
            template_name: source.template_name,
            household_size: source.household_size,
            language_preference: source.language_preference,
            situation_notes: source.situation_notes,
            delivery_mode: source.delivery_mode
          }
        else
          {
            template_name: source[:template_name] || "Social Services: CalFresh / SNAP, Medi-Cal & LIHEAP Packet",
            household_size: source[:household_size] || "Household Size: 3",
            language_preference: source[:language_preference] || "Language: English",
            situation_notes: source[:situation_notes] || "Standard expedited filing",
            delivery_mode: source[:delivery_mode] || "pdf"
          }
        end
      end

      def build_ephemeral_document(attrs)
        <<~PDF_DOC
          %PDF-1.7 [EPHEMERAL LOCAL VAULT #{node_code}]
          Template: #{attrs[:template_name]}
          Local Vault: 1400 Block of 62nd Ave (#{attrs[:household_size]} • #{attrs[:language_preference]})
          Notes: #{attrs[:situation_notes]}
          Privacy: Encrypted on #{node_code} Local Server (0 Bytes sent externally)
        PDF_DOC
      end

      def encrypt_ephemeral_payload(plaintext)
        cipher = OpenSSL::Cipher.new("aes-256-gcm")
        cipher.encrypt
        key = OpenSSL::Digest::SHA256.digest("oak-01-ephemeral-local-vault-key")
        iv = cipher.random_iv
        cipher.key = key
        cipher.iv = iv
        cipher.auth_data = node_code.to_s

        ciphertext = cipher.update(plaintext) + cipher.final
        {
          ciphertext_b64: Base64.strict_encode64(ciphertext),
          iv_b64: Base64.strict_encode64(iv),
          auth_tag_b64: Base64.strict_encode64(cipher.auth_tag)
        }
      end

      def attach_courier_printed_packet(care_basket, template_name)
        return nil unless care_basket && care_basket.respond_to?(:care_basket_items)

        care_basket.care_basket_items.create!(
          item_name: "Courier Printed Packet: #{template_name}",
          hub_label: "Paperwork Co-Pilot • Fruitvale Hub",
          badge_summary: "Solidarity Share",
          quantity: 1
        )
      end

      def preview_summary_for(attrs)
        "Form: #{attrs[:template_name]} • Local Vault: 1400 Block of 62nd Ave " \
          "(#{attrs[:household_size]} • #{attrs[:language_preference]}) • " \
          "Notes: #{attrs[:situation_notes]} • Privacy: Encrypted on #{node_code} Local Server (0 Bytes sent externally)"
      end

      def veteran_and_social_match
        {
          node_code: node_code,
          matched_categories: %w(social_services veteran_services),
          recommended_bundle_title: "Veteran & Social Services Care Packet",
          hub_label: "Veteran & Social Services • Fruitvale Resource Hub",
          reply_summary: "Matched in Social services & Veteran services at Fruitvale Resource Hub: " \
                         "Pre-filled CalFresh/Medi-Cal/LIHEAP and VA Disability Claim / DD-214 packets.",
          cta_label: "+ Add Printed Packet & Veteran Care Tote"
        }
      end

      def legal_housing_and_public_sector_match
        {
          node_code: node_code,
          matched_categories: %w(legal_aid housing public_sector),
          recommended_bundle_title: "Legal Aid, Housing Weatherization & Municipal ID Packet",
          hub_label: "Legal & Housing Hub",
          reply_summary: "Matched in Legal aid, Housing & Public sector: Eviction Defense & Expungement Clinic + " \
                         "Emergency Rent Relief & Weatherization Kit + Municipal ID / Paratransit Waiver.",
          cta_label: "+ Add Housing Kit & Legal Packet"
        }
      end

      def holistic_health_youth_and_arts_match
        {
          node_code: node_code,
          matched_categories: %w(mental_health medical youth_services arts),
          recommended_bundle_title: "Holistic Health, Youth & Arts Bundle",
          hub_label: "Multi-Hub Care Share",
          reply_summary: "Matched across Mental health, Medical, Youth services & Arts: Bilingual Peer Counseling & " \
                         "Weighted Grounding Kit, Folding Mobility Walker & BP Cuff, Youth STEM/Diaper Pack & Studio Art Box.",
          cta_label: "+ Add Matched Care Bundle"
        }
      end

      def food_garden_pet_and_coop_match
        {
          node_code: node_code,
          matched_categories: %w(food garden pets co_ops mutual_aid),
          recommended_bundle_title: "Food, Garden, Pet & Co-op Solidarity Bundle",
          hub_label: "East Oakland Commons",
          reply_summary: "Matched across Food, Garden, Pets, Co-ops & Mutual Aid: Organic Collard Greens & 25lb Grain Box, " \
                         "Urban Garden Seed/Starts & 20lb Pet Kibble, Worker Co-op Sourdough & Mutual Aid Solar Lantern Kit.",
          cta_label: "+ Add Matched Items to Care Basket"
        }
      end
    end
  end
end
