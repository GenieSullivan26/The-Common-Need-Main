# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Decidim::CommonNeed Permissions & NonProfitHandler Verification" do
  describe Decidim::Verifications::NonProfitHandler do
    it "validates 501(c)(3) / cooperative EIN format (/\\A\\d{2}-\\d{7}\\z/), organization_name, and charter acceptance" do
      handler = Decidim::Verifications::NonProfitHandler.from_params(
        ein_number: "94-3184920",
        organization_name: "East Oakland Collective Pantry",
        hub_address: "7800 MacArthur Blvd",
        collective_charter_accepted: true
      )
      expect(handler).to be_valid
      expect(handler.unique_id).to eq("non_profit_ein_94-3184920")
      expect(handler.metadata[:node_code]).to eq("#OAK-01")
    end

    it "rejects malformed EIN numbers or unaccepted solidarity charter" do
      bad_ein = Decidim::Verifications::NonProfitHandler.from_params(
        ein_number: "943184920",
        organization_name: "Unverified Org",
        collective_charter_accepted: true
      )
      expect(bad_ein).to be_invalid

      unaccepted_charter = Decidim::Verifications::NonProfitHandler.from_params(
        ein_number: "94-3184920",
        organization_name: "East Oakland Collective Pantry",
        collective_charter_accepted: false
      )
      expect(unaccepted_charter).to be_invalid
    end
  end

  describe Decidim::CommonNeed::Permissions do
    let(:anonymous_user) { nil }
    let(:member_user) { OpenStruct.new(id: 1, admin?: false, roles: []) }
    let(:node_admin_user) { OpenStruct.new(id: 2, admin?: false, roles: ["node_admin"]) }

    def check_permission(user, action, scope: :public, context: {})
      perm_action = Decidim::PermissionAction.new(scope: scope, action: action, subject: :common_need)
      Decidim::CommonNeed::Permissions.new(user, perm_action, context).permissions.allowed?
    end

    it "grants unconditional access (zero means-testing) to all Member actions even without login or verification" do
      Decidim::CommonNeed::Permissions::UNCONDITIONAL_MEMBER_ACTIONS.each do |action|
        expect(check_permission(anonymous_user, action)).to be_truthy
        expect(check_permission(member_user, action)).to be_truthy
      end
    end

    it "allows logged-in Volunteers to view routes, confirm stops, and claim shifts" do
      Decidim::CommonNeed::Permissions::VOLUNTEER_COURIER_ACTIONS.each do |action|
        expect(check_permission(anonymous_user, action)).to be_falsy
        expect(check_permission(member_user, action)).to be_truthy
      end
    end

    it "gates Partner Portal actions behind NonProfitHandler verification" do
      Decidim::CommonNeed::Permissions::PARTNER_PORTAL_ACTIONS.each do |action|
        expect(check_permission(member_user, action)).to be_falsy
        expect(check_permission(member_user, action, context: { non_profit_authorized: true })).to be_truthy
      end

      Decidim::Authorization.create!(
        user: member_user,
        name: "non_profit_handler",
        granted_at: Time.current
      )
      expect(check_permission(member_user, :post_surplus)).to be_truthy
    end

    it "gates Local Node Admin and Central Hub Federation actions to node or federation coordinators" do
      Decidim::CommonNeed::Permissions::NODE_AND_FEDERATION_ADMIN_ACTIONS.each do |action|
        expect(check_permission(member_user, action)).to be_falsy
        expect(check_permission(node_admin_user, action)).to be_truthy
      end

      expect(check_permission(member_user, :manage_local_node, scope: :admin)).to be_falsy
      expect(check_permission(node_admin_user, :manage_local_node, scope: :admin)).to be_truthy
    end
  end
end
