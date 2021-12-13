#frozen_string_literal: true

require 'command_class'

module Authentication

  class InitializeAuthHost
    extend CommandClass::Include

    command_class(
      dependencies: {
        logger: Rails.logger,
        auth_initializer: Authentication::Default::InitializeDefaultAuth.new,
      },
      inputs: %i[conjur_account authenticator service_id resource current_user client_ip host_id annotations]
    ) do
      def call
        policy_details = initialize_host_policy

        #raise ArgumentError, @auth_data.errors.full_messages unless @auth_data.valid?
        # @auth_initializer.(conjur_account: @conjur_account, service_id: @service_id, auth_data: @auth_data)

        host_policy
      rescue => e
        raise e
      end

      private

      def host_policy
        @host_policy ||= ApplicationController.renderer.render(
          template: "policies/authn-k8s-host",
          locals: {
            service_id: @service_id,
            authenticator: @authenticator,
            hosts: [ {id: @host_id, annotations: @annotations} ]
          }
        )
      end

      def initialize_host_policy
        Policy::LoadPolicy.new.(
          delete_permitted: false,
          action: :update,
          resource: @resource,
          policy_text: host_policy,
          current_user: @current_user,
          client_ip: @client_ip
        )
      end
    end
  end

end
