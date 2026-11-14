# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Permissions policy for The Common Need 5-Role PWA Suite.
    # - Enforces Unconditional Solidarity (zero means-testing) for all Member actions
    #   (catalog browsing, basket checkout, local AI paperwork helper, calendar RSVP, voting).
    # - Gates Partner Non-Profit actions via `Decidim::Verifications::NonProfitHandler`.
    # - Gates Local Node Admin and Federation Central Hub actions to authorized node admins.
    class Permissions < Decidim::DefaultPermissions
      UNCONDITIONAL_MEMBER_ACTIONS = %i(
        read
        browse_catalog
        checkout_basket
        use_local_ai_helper
        rsvp_calendar_event
        cast_solidarity_vote
      ).freeze

      VOLUNTEER_COURIER_ACTIONS = %i(
        view_route
        confirm_stop
        claim_volunteer_shift
      ).freeze

      PARTNER_PORTAL_ACTIONS = %i(
        manage_partner_hub
        post_surplus
        verify_crates
        publish_partner_event
      ).freeze

      NODE_AND_FEDERATION_ADMIN_ACTIONS = %i(
        manage_local_node
        moderate_partner_application
        resolve_moderation_flag
        peer_federated_node
        dispatch_inter_node_transfer
        view_federation_telemetry
      ).freeze

      def permissions
        return permission_action unless permission_action.scope.in?([:public, :admin])

        if permission_action.scope == :admin
          apply_admin_permissions!
          return permission_action
        end

        apply_public_permissions!
        permission_action
      end

      private

      def apply_public_permissions!
        if UNCONDITIONAL_MEMBER_ACTIONS.include?(permission_action.action)
          # Unconditional solidarity: zero means-testing!
          allow!
        elsif VOLUNTEER_COURIER_ACTIONS.include?(permission_action.action)
          toggle_allow(user.present?)
        elsif PARTNER_PORTAL_ACTIONS.include?(permission_action.action)
          toggle_allow(verified_non_profit_partner?)
        elsif NODE_AND_FEDERATION_ADMIN_ACTIONS.include?(permission_action.action)
          toggle_allow(node_or_federation_coordinator?)
        end
      end

      def apply_admin_permissions!
        toggle_allow(node_or_federation_coordinator?)
      end

      def verified_non_profit_partner?
        return false unless user
        return true if user.respond_to?(:admin?) && user.admin?
        return true if context[:non_profit_authorized] == true

        if defined?(Decidim::Authorization)
          Decidim::Authorization.where(
            user: user,
            name: "non_profit_handler"
          ).where.not(granted_at: nil).exists?
        else
          false
        end
      rescue StandardError
        false
      end

      def node_or_federation_coordinator?
        return false unless user

        (user.respond_to?(:admin?) && user.admin?) ||
          (user.respond_to?(:roles) && (Array(user.roles) & %w(admin node_admin federation_coordinator)).any?) ||
          context[:node_admin] == true
      end
    end
  end
end
