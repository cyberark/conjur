#frozen_string_literal: true

require 'command_class'

module Authentication
  class InitializeAuth
    extend CommandClass::Include

    command_class(
      dependencies: {
        logger: Rails.logger,
        secrets: Secret,
        auth_initializer: Authentication::AuthnK8s::InitializeK8sAuth.new,
      },
      inputs: %i[conjur_account service_id resource current_user client_ip auth_data]
    ) do
      def call
        policy_details = initialize_auth_policy

        #return false unless initializer.validate?
        @auth_initializer.(conjur_account: @conjur_account, service_id: @service_id, auth_data: @auth_data)
      rescue => e
        raise e
      end

      def auth_name
        @auth_initializer.auth_name
      end

      private

      def auth_policy
        @auth_policy ||= ApplicationController.renderer.render(
          template: "policies/%s" % [ auth_name ],
          locals: {service_id: @service_id}
        )
      end

      def initialize_auth_policy
        puts auth_policy
        Policy::LoadPolicy.new.(
          delete_permitted: false,
          action: :update,
          resource: @resource,
          policy_text: auth_policy,
          current_user: @current_user,
          client_ip: @client_ip
        )
      end
    end
  end
end
