# frozen_string_literal: true

require 'command_class'

module Authentication
  module AuthnOidc

    class OidcAuthenticatorData
      attr_reader :provider_uri, :id_token_user, :json_data

      def initialize(raw_post)
        @json_data = JSON.parse(raw_post)

        @provider_uri = @json_data['provider_uri']
        @id_token_user = @json_data['id-token-user-property']
      end

      # TODO Validation: Need to validate json_data contents and each individual variable
    end

    class InitializeOidcAuth
      extend CommandClass::Include
      
      def auth_name
        "authn-oidc"
      end

      command_class(
        dependencies: {
          secret: Secret
        },
        inputs: %i[conjur_account service_id auth_data]
      ) do
        def call
          unless @auth_data.nil?
            @auth_data.json_data.each {|key, value| @secret.create(resource_id: variable_id(key), value: value) }
          end
        rescue => e
          raise e
        end

        private

        # TODO Should this go in its own module so each auth initializer can share it?
        def variable_id(variable_name)
          policy_branch = "conjur/%s/%s" % [ auth_name, @service_id ]
          "%s:variable:%s/%s" % [ @conjur_account, policy_branch, variable_name ] 
        end
      end
    end

  end
end
