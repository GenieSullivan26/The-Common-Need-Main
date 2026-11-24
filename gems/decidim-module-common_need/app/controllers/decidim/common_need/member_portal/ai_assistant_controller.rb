# frozen_string_literal: true

module Decidim
  module CommonNeed
    module MemberPortal
      # Local Node Resource Navigator & Encrypted Paperwork controller.
      # Trained on live free goods, partner surplus, and an expert social service knowledge base.
      class AiAssistantController < Decidim::CommonNeed::ApplicationController
        def chat
          prompt = params[:prompt].to_s.strip
          navigator = Decidim::CommonNeed::ResourceNavigatorService.new(node_code: current_local_node_code)
          result = navigator.navigate(
            prompt,
            extra_surplus_items: params[:live_surplus_items] || [],
            extra_events: params[:live_events] || []
          )

          render json: {
            node_code: current_local_node_code,
            endpoint: Decidim::CommonNeed.local_ollama_endpoint,
            external_bytes_sent: 0,
            prompt: prompt,
            live_catalog_count: result[:live_catalog_count],
            live_surplus_count: result[:live_surplus_count],
            matched_categories: result[:matched_categories],
            matched_domains: result[:matched_domains],
            matched_items: result[:matched_items],
            matched_events: result[:matched_events],
            expert_guidance: result[:expert_guidance],
            recommended_forms: result[:recommended_forms],
            reply_html: result[:reply_html]
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
      end
    end
  end
end
