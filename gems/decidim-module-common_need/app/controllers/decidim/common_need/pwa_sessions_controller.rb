# frozen_string_literal: true

module Decidim
  module CommonNeed
    # Handles Decidim Single Sign-On (Devise + Decidim::Verifications) for the
    # Member, Volunteer, and Partner Non-Profit PWAs and redirects authenticated
    # users to their role-specific PWA portal based on user type.
    class PwaSessionsController < ApplicationController
      layout false

      def new
        @target_role = params[:role].presence || "member"
      end

      def create
        result = Decidim::CommonNeed::DecidimSignOnService.new(
          email: params[:email],
          password: params[:password],
          requested_user_type: params[:user_type],
          user: current_user,
          organization: current_organization
        ).call

        if result[:authenticated]
          @authenticated_session = result
          redirect_to result[:redirect_path]
        else
          @auth_error = result[:error]
          render :new, status: :unprocessable_entity
        end
      end

      def destroy
        @authenticated_session = nil
        redirect_to "/?role=member&signed_out=1"
      end
    end
  end
end
