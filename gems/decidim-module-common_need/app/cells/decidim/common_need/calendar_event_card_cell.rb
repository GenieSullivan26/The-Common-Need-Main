# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Renders a Partner Event card (`Decidim::Meetings::Meeting` or event hash/struct)
    # with category tags, date/time badge, host hub & distance, accessibility/interpretation badge,
    # `+ RSVP on Local Node` button, and `🚚 Request Event Box Delivery` or `🤖 Pre-Fill Clinic Forms` button.
    class CalendarEventCardCell < Decidim::ViewModel
      def show
        render :show
      end

      def day_code
        fetch_attr(:day, "Tue Nov 3")
      end

      def org_code
        fetch_attr(:org, "east_oakland")
      end

      def topic_code
        fetch_attr(:topic, "food")
      end

      def latitude
        fetch_attr(:lat, "37.7651")
      end

      def longitude
        fetch_attr(:lng, "-122.1755")
      end

      def location_label
        fetch_attr(:location, "7800 MacArthur Blvd")
      end

      def search_keywords
        fetch_attr(:keywords, "food garden seed swap hot meal dinner east oakland collective pantry")
      end

      def category_chip
        fetch_attr(:category_chip, "🍎 FOOD & 🌱 GARDEN")
      end

      def date_time_badge
        fetch_attr(:date_time_badge, "Tue Nov 3 • 4:00 PM – 7:00 PM")
      end

      def title
        fetch_attr(:title, "Community Harvest Dinner & Winter Seed/Compost Swap")
      end

      def host_and_location_sub
        fetch_attr(:host_sub, "Hosted by: East Oakland Collective Pantry • 📍 7800 MacArthur Blvd (1.2 mi)")
      end

      def description
        fetch_attr(:description, "Hot plantain & black bean dinner served to all neighbors, plus winter brassica seedlings, soil testing, and take-home produce boxes.")
      end

      def accessibility_badge
        fetch_attr(:accessibility_badge, "✓ Childcare Space • ✓ ADA Ramp • 42 / 80 Spots Registered")
      end

      def rsvp_button_label
        fetch_attr(:rsvp_label, "+ RSVP on Local Node")
      end

      def rsvp_title
        fetch_attr(:rsvp_title, title)
      end

      def secondary_action_type
        fetch_attr(:secondary_action_type, :delivery_box).to_sym
      end

      def secondary_button_label
        fetch_attr(:secondary_label, "🚚 Request Event Box Delivery")
      end

      def secondary_payload_title
        fetch_attr(:secondary_payload_title, "#{title} Home Delivery Box")
      end

      def secondary_hub_label
        fetch_attr(:secondary_hub_label, "Calendar Event • East Oakland Hub")
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
