# frozen_string_literal: true

require 'command_class'

module Authentication

  module Default
    # Performs additional setup for newly persisted authenticators
    class InitializeDefaultAuth
      extend CommandClass::Include

      command_class(
        dependencies: {
          secret: Secret
        },
        inputs: %i[conjur_account service_id auth_data]
      ) do
        def call
          @auth_data&.json_data&.each do |key, value|
            policy_branch = format("conjur/%s/%s", @auth_data.auth_name, @service_id)
            variable_id = format("%s:variable:%s/%s", @conjur_account, policy_branch, key)

            @secret.create(resource_id: variable_id, value: value)
          end
        end
      end

    end
  end

  # Persists a new authenticator + webservice in Conjur
  class PersistAuth
    extend CommandClass::Include

    command_class(
      dependencies: {
        logger: Rails.logger,
        auth_initializer: Authentication::Default::InitializeDefaultAuth.new,
        policy_loader: Policy::LoadPolicy.new,
        auth_data_class: Authentication::AuthnK8s::K8sAuthenticatorData
      },
      inputs: %i[conjur_account service_id resource current_user client_ip request_data]
    ) do
      def call
        auth_data = @auth_data_class.new(@request_data)
        raise ArgumentError, auth_data.errors.full_messages unless auth_data.valid?

        policy_details = initialize_auth_policy(
          policy_loader: @policy_loader,
          resource: @resource,
          current_user: @current_user,
          client_ip: @client_ip,
          auth_policy: auth_policy(auth_data: auth_data, service_id: @service_id)
        )

        @auth_initializer.(conjur_account: @conjur_account, service_id: @service_id, auth_data: auth_data)

        policy_details
      end

      private

      def auth_policy(auth_data:, service_id:)
        @auth_policy ||= ApplicationController.renderer.render(
          template: format("policies/%s", auth_data.auth_name),
          locals: { service_id: service_id, auth_data: auth_data }
        )
      end

      def initialize_auth_policy(policy_loader:, resource:, current_user:, client_ip:, auth_policy:)
        policy_loader.(
          delete_permitted: false,
          action: :update,
          resource: resource,
          policy_text: auth_policy,
          current_user: current_user,
          client_ip: client_ip
        )
      end
    end
  end

end
