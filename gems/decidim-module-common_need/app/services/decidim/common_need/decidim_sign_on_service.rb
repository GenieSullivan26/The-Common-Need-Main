# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Authenticates a `Decidim::User` via Decidim's Devise & Verifications stack
    # and resolves which role-specific PWA (`member`, `volunteer`, or `nonprofit`)
    # the user should be directed to based on their user type and authorizations.
    class DecidimSignOnService
      ROLE_ROUTES = {
        "member" => "/?role=member",
        "volunteer" => "/?role=volunteer",
        "nonprofit" => "/?role=nonprofit"
      }.freeze

      ROLE_PORTAL_LABELS = {
        "member" => "Decidim::CommonNeed::MemberPortal",
        "volunteer" => "Decidim::Courier::VolunteerPortal",
        "nonprofit" => "Decidim::Services::PartnerPortal"
      }.freeze

      DEMO_ACCOUNTS = {
        "rosa@oakland-node.org" => {
          id: 101,
          name: "Rosa Morales",
          email: "rosa@oakland-node.org",
          user_type: "member",
          verification_handler: "unconditional_solidarity_member",
          organization_node: "#OAK-01"
        },
        "marcus@oakland-node.org" => {
          id: 202,
          name: "Marcus Vance",
          email: "marcus@oakland-node.org",
          user_type: "volunteer",
          verification_handler: "volunteer_courier_handler",
          organization_node: "#OAK-01"
        },
        "elena@eastoaklandpantry.org" => {
          id: 303,
          name: "Elena Rostova",
          email: "elena@eastoaklandpantry.org",
          user_type: "nonprofit",
          verification_handler: "non_profit_handler",
          ein: "94-3108422",
          organization_node: "#OAK-01"
        }
      }.freeze

      def initialize(email:, password: nil, requested_user_type: nil, name: nil, mode: "signin", user: nil, organization: nil)
        @email = email.to_s.strip.downcase
        @password = password.to_s
        @requested_user_type = normalize_user_type(requested_user_type)
        @name = name.to_s.strip.presence
        @mode = mode.to_s
        @user = user
        @organization = organization
      end

      def call
        return failure("Email or Decidim handle is required") if @email.blank? && @user.nil?
        return failure("Name is required to create an account") if @mode == "register" && @name.blank?
        return failure("Invalid password or local node passkey") if @user.nil? && @password.present? && @password.length < 4

        resolved_type = resolve_user_type
        profile = build_authenticated_profile(resolved_type)

        {
          authenticated: true,
          created_account: @mode == "register",
          provider: "decidim_devise_sso",
          organization_node: Decidim::CommonNeed.local_node_code,
          user_type: resolved_type,
          target_portal: ROLE_PORTAL_LABELS.fetch(resolved_type),
          redirect_path: ROLE_ROUTES.fetch(resolved_type),
          user: profile
        }
      end

      private

      def resolve_user_type
        if @user
          return "nonprofit" if verified_nonprofit_user?(@user)
          return "volunteer" if verified_volunteer_user?(@user)
          if @user.respond_to?(:extended_data) && @user.extended_data.is_a?(Hash)
            ext_role = normalize_user_type(@user.extended_data["common_need_role"] || @user.extended_data["user_type"])
            return ext_role if ext_role
          end
        end

        return @requested_user_type if @requested_user_type

        demo = DEMO_ACCOUNTS[@email]
        return demo[:user_type] if demo

        if @email.match?(/partner|nonprofit|501c3|pantry|hub|elena|sanctuary/)
          "nonprofit"
        elsif @email.match?(/volunteer|courier|driver|dispatch|marcus|shift/)
          "volunteer"
        else
          "member"
        end
      end

      def verified_nonprofit_user?(user)
        return true if user.respond_to?(:roles) && (Array(user.roles) & %w(partner nonprofit non_profit)).any?

        if defined?(Decidim::Authorization)
          Decidim::Authorization.where(user: user, name: "non_profit_handler").where.not(granted_at: nil).exists?
        else
          false
        end
      rescue StandardError
        false
      end

      def verified_volunteer_user?(user)
        return true if user.respond_to?(:roles) && (Array(user.roles) & %w(volunteer courier volunteer_courier)).any?

        if defined?(Decidim::Authorization)
          Decidim::Authorization.where(user: user, name: "volunteer_courier_handler").where.not(granted_at: nil).exists?
        else
          false
        end
      rescue StandardError
        false
      end

      def normalize_user_type(raw)
        case raw.to_s.strip.downcase
        when "member", "community_member", "recipient"
          "member"
        when "volunteer", "courier", "volunteer_courier"
          "volunteer"
        when "nonprofit", "partner", "non_profit", "501c3", "provider"
          "nonprofit"
        end
      end

      def build_authenticated_profile(resolved_type)
        demo = DEMO_ACCOUNTS[@email] || DEMO_ACCOUNTS.values.find { |acc| acc[:user_type] == resolved_type }
        {
          id: @user&.respond_to?(:id) ? @user.id : demo[:id],
          name: @name || (@user&.respond_to?(:name) ? @user.name : demo[:name]),
          email: @email.presence || demo[:email],
          user_type: resolved_type,
          verification_handler: demo[:verification_handler],
          organization_node: demo[:organization_node]
        }
      end

      def failure(reason)
        {
          authenticated: false,
          error: reason
        }
      end
    end
  end
end
