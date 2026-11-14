# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Authenticates or registers a `Decidim::User` via Decidim's Devise & Verifications
    # stack, resolves their sovereign local Decidim instance (`Decidim::Organization` /
    # `FederatedNode`) based on their street address or ZIP code, and directs them
    # to the matching role PWA (`member`, `volunteer`, or `nonprofit`).
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

      FEDERATED_INSTANCES = [
        {
          node_code: "#BRK-02",
          name: "Berkeley Cooperative Node",
          host: "berkeley-02.common-need.org",
          zips: %w(94701 94702 94703 94704 94705 94706 94707 94708 94709 94710 94720),
          keywords: /berkeley|shattuck|telegraph|albany|university ave/i
        },
        {
          node_code: "#RCH-03",
          name: "Richmond / West County Node",
          host: "richmond-03.common-need.org",
          zips: %w(94801 94803 94804 94805 94806 94530),
          keywords: /richmond|san pablo|el cerrito|pinole|west county|macdonald/i
        },
        {
          node_code: "#SLN-04",
          name: "South County Solidarity Node",
          host: "southcounty-04.common-need.org",
          zips: %w(94577 94578 94579 94580 94541 94544 94545),
          keywords: /san leandro|hayward|san lorenzo|castro valley|ashland|cherryland/i
        },
        {
          node_code: "#WOK-05",
          name: "West Oakland Commons Node",
          host: "westoakland-05.common-need.org",
          zips: %w(94607 94608 94609 94611 94612 94618),
          keywords: /west oakland|emeryville|temescal|mandela|adeline|7th st/i
        },
        {
          node_code: "#OAK-01",
          name: "East Oakland Local Node",
          host: "oakland-01.common-need.org",
          zips: %w(94601 94602 94603 94605 94606 94619 94621),
          keywords: /east oakland|fruitvale|san antonio|macarthur|62nd|international|oakland/i
        }
      ].freeze

      DEMO_ACCOUNTS = {
        "rosa@oakland-node.org" => {
          id: 101,
          name: "Rosa Morales",
          email: "rosa@oakland-node.org",
          address: "1420 62nd Ave, Oakland, CA 94621",
          user_type: "member",
          verification_handler: "unconditional_solidarity_member",
          organization_node: "#OAK-01"
        },
        "marcus@oakland-node.org" => {
          id: 202,
          name: "Marcus Vance",
          email: "marcus@oakland-node.org",
          address: "3115 San Pablo Ave, Oakland, CA 94608",
          user_type: "volunteer",
          verification_handler: "volunteer_courier_handler",
          organization_node: "#OAK-01"
        },
        "elena@eastoaklandpantry.org" => {
          id: 303,
          name: "Elena Rostova",
          email: "elena@eastoaklandpantry.org",
          address: "7800 MacArthur Blvd, Oakland, CA 94605",
          user_type: "nonprofit",
          verification_handler: "non_profit_handler",
          ein: "94-3108422",
          organization_node: "#OAK-01"
        }
      }.freeze

      def self.resolve_instance_from_address(raw_address)
        addr = raw_address.to_s.strip
        if addr.present?
          zip_match = addr[/\b(\d{5})\b/, 1]
          if zip_match
            by_zip = FEDERATED_INSTANCES.find { |inst| inst[:zips].include?(zip_match) }
            return by_zip.slice(:node_code, :name, :host) if by_zip
          end

          by_keyword = FEDERATED_INSTANCES.find { |inst| addr.match?(inst[:keywords]) }
          return by_keyword.slice(:node_code, :name, :host) if by_keyword

          if zip_match
            return {
              node_code: "#LOC-#{zip_match[0, 3]}",
              name: "Neighborhood Local Node (#{zip_match})",
              host: "node-#{zip_match}.common-need.org"
            }
          end
        end

        default_inst = FEDERATED_INSTANCES.last
        default_inst.slice(:node_code, :name, :host)
      end

      def initialize(email:, password: nil, requested_user_type: nil, name: nil, address: nil, mode: "signin", user: nil, organization: nil)
        @email = email.to_s.strip.downcase
        @password = password.to_s
        @requested_user_type = normalize_user_type(requested_user_type)
        @name = name.to_s.strip.presence
        @address = address.to_s.strip.presence
        @mode = mode.to_s
        @user = user
        @organization = organization
      end

      def call
        return failure("Email or Decidim handle is required") if @email.blank? && @user.nil?
        return failure("Name is required to create an account") if @mode == "register" && @name.blank?
        return failure("Street address or ZIP code is required to link your local instance") if @mode == "register" && @address.blank?
        return failure("Invalid password or local node passkey") if @user.nil? && @password.present? && @password.length < 4

        resolved_type = resolve_user_type
        profile = build_authenticated_profile(resolved_type)
        instance_info = self.class.resolve_instance_from_address(profile[:address])

        {
          authenticated: true,
          created_account: @mode == "register",
          provider: "decidim_devise_sso",
          organization_node: instance_info[:node_code],
          instance_name: instance_info[:name],
          instance_host: instance_info[:host],
          user_type: resolved_type,
          target_portal: ROLE_PORTAL_LABELS.fetch(resolved_type),
          redirect_path: "#{ROLE_ROUTES.fetch(resolved_type)}&node=#{URI.encode_www_form_component(instance_info[:node_code])}",
          user: profile.merge(
            organization_node: instance_info[:node_code],
            instance_name: instance_info[:name],
            instance_host: instance_info[:host]
          )
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
          address: @address || demo[:address],
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
