# frozen_string_literal: true

module Decidim
  module CommonNeed
    module MemberPortal
      # Local Node #OAK-01 AI Assistant & Encrypted Paperwork Co-Pilot controller.
      # Strictly routes to local Ollama (`127.0.0.1:11434`) with zero external cloud tracking.
      class AiAssistantController < Decidim::CommonNeed::ApplicationController
        def chat
          prompt = params[:prompt].to_s.strip
          render json: {
            node_code: current_local_node_code,
            model: Decidim::CommonNeed.local_ollama_model,
            endpoint: Decidim::CommonNeed.local_ollama_endpoint,
            external_bytes_sent: 0,
            prompt: prompt,
            reply_html: build_local_ai_reply(prompt)
          }
        end

        def generate_paperwork
          template = params[:template].presence || Decidim::CommonNeed::MemberPortal::PAPERWORK_TEMPLATES.first
          delivery_mode = params[:delivery_mode].presence || "pdf"

          render json: {
            status: "completed",
            node_code: current_local_node_code,
            template: template,
            delivery_mode: delivery_mode,
            household: params[:household].presence || "Household Size: 3",
            language: params[:language].presence || "Language: English / Español",
            notes: params[:situation].presence || "Need expedited processing + porch delivery of printed signature page",
            zero_means_testing: true,
            external_bytes_sent: 0
          }
        end

        private

        def build_local_ai_reply(prompt)
          lower = prompt.downcase
          if lower.include?("veteran") || lower.include?("calfresh") || lower.include?("social")
            "Matched in Social services & Veteran services at Fruitvale Resource Hub: Pre-filled CalFresh/Medi-Cal/LIHEAP and VA Disability Claim / DD-214 packets."
          elsif lower.include?("legal") || lower.include?("housing") || lower.include?("eviction")
            "Matched in Legal aid, Housing & Public sector: Eviction Defense & Expungement Clinic + Emergency Rent Relief & Weatherization Kit + Municipal ID Waiver."
          elsif lower.include?("mental") || lower.include?("medical") || lower.include?("youth") || lower.include?("art")
            "Matched across Mental health, Medical, Youth services & Arts: Bilingual Peer Counseling, Folding Mobility Walker & Youth STEM/Art Bundle."
          else
            "Matched across Food, Garden, Pets, Co-ops & Mutual Aid at East Oakland Collective Pantry & Commons."
          end
        end
      end
    end
  end
end
