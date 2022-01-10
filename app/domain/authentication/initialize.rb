#frozen_string_literal: true

require 'command_class'

module Authentication

  module Default
    class InitializeDefaultAuth
      extend CommandClass::Include

      command_class(
        dependencies: {
          secret: Secret
        },
        inputs: %i[conjur_account service_id auth_data]
      ) do
        def call
          raise ArgumentError, "auth_data cannot be nil" if @auth_data.nil?
          unless @auth_data.nil? or @auth_data.json_data.nil?
            @auth_data.json_data.each {|key, value| @secret.create(resource_id: variable_id(key), value: value) }
          end
        end

        private

        # TODO Should this go in its own module so each auth initializer can share it?
        def variable_id(variable_name)
          policy_branch = "conjur/%s/%s" % [ @auth_data.auth_name, @service_id ]
          "%s:variable:%s/%s" % [ @conjur_account, policy_branch, variable_name ] 
        end
      end

    end
  end

  class PersistAuth
    extend CommandClass::Include

    command_class(
      dependencies: {
        logger: Rails.logger,
        auth_initializer: Authentication::Default::InitializeDefaultAuth.new,
        policy_loader: Policy::LoadPolicy.new,
      },
      inputs: %i[conjur_account service_id resource current_user client_ip auth_data]
    ) do
      def call
        raise ArgumentError, @auth_data.errors.full_messages unless @auth_data.valid?
        policy_details = initialize_auth_policy

        @auth_initializer.(conjur_account: @conjur_account, service_id: @service_id, auth_data: @auth_data)

        policy_details[:policy].values[:policy_text]
      rescue => e
        raise e
      end

      def auth_name
        @auth_data.auth_name
      end

      private

      def auth_policy
        @auth_policy ||= ApplicationController.renderer.render(
          template: "policies/%s" % auth_name,
          locals: {service_id: @service_id}
        )
      end

      def initialize_auth_policy
        @policy_loader.(
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
