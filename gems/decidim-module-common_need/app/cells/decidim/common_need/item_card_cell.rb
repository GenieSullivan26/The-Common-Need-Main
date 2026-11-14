# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Renders an individual item or community service offering inside a HubCardCell:
    # category chip (`🍎 FOOD`), item title, dietary/safety tags, yield & stock,
    # and stepper controls (`- / +`), `+ Add Share`, or `🤖 Auto-Fill` paperwork trigger.
    class ItemCardCell < Decidim::ViewModel
      def show
        render :show
      end

      def category_slug
        fetch_attr(:category, "food")
      end

      def category_chip_label
        fetch_attr(:category_chip, "🍎 FOOD")
      end

      def title
        fetch_attr(:title, "Organic Collard Greens, Kale & 25lb Staple Grain Box")
      end

      def tags_summary
        fetch_attr(:tags_summary, "Vegan / GF / Halal • Fresh Greens + Rice, Pinto Beans & Oats")
      end

      def yield_and_stock_summary
        fetch_attr(:yield_summary, "Yield: ~39 Nourishing Family Meals (28 lbs) • High Stock")
      end

      def action_type
        fetch_attr(:action_type, :add_share).to_sym
      end

      def stepper_key
        fetch_attr(:stepper_key, "collards")
      end

      def initial_qty
        fetch_attr(:initial_qty, 1)
      end

      def button_label
        fetch_attr(:button_label, "+ Add Share")
      end

      def basket_item_name
        fetch_attr(:basket_item_name, title)
      end

      def basket_hub_label
        fetch_attr(:basket_hub_label, options[:hub_label] || "East Oakland Hub")
      end

      def paperwork_template_title
        fetch_attr(:paperwork_template, title)
      end

      private

      def fetch_attr(key, default = nil)
        if model.respond_to?(key)
          model.public_send(key) || default
        elsif model.is_a?(Hash)
          model[key] || model[key.to_s] || default
        else
          default
        end
      end
    end
  end
end
