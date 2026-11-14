# frozen_string_literal: true

module Decidim
  module CommonNeed
    module MemberPortal
      # Manages the Multi-Hub Care Basket, accessibility handoff notes, and free courier dispatch.
      class CareBasketsController < Decidim::CommonNeed::ApplicationController
        def show
          render json: {
            shift_code: "SHIFT #OAK-409",
            window: "2:35 PM – 2:50 PM",
            stops_away: 2,
            handoff_note: "Handoff: Walk up 4 porch steps & wait 60s",
            access_principle: "UNCONDITIONAL SOLIDARITY"
          }
        end

        def add_item
          render json: {
            status: "added",
            item_name: params[:item_name].presence || "Community Share",
            hub_label: params[:hub_label].presence || "Local Community Hub"
          }
        end

        def adjust_quantity
          render json: {
            status: "updated",
            item_key: params[:item_key],
            delta: params[:delta].to_i
          }
        end

        def update_handoff
          steps = ActiveModel::Type::Boolean.new.cast(params[:bring_up_porch_steps])
          wait = ActiveModel::Type::Boolean.new.cast(params[:wait_60s_at_door])
          parts = []
          parts << "Walk up 4 porch steps" if steps
          parts << "wait 60s" if wait
          note = parts.any? ? "Handoff: #{parts.join(' & ')}" : "Handoff: Standard door dropoff"

          render json: { status: "updated", handoff_note: note }
        end

        def checkout
          render json: {
            status: "dispatched",
            shift_code: "SHIFT #OAK-409",
            window: "2:35 PM – 2:50 PM (2 Stops Away)",
            zero_map_tiles: true
          }
        end
      end
    end
  end
end
