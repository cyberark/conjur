# frozen_string_literal: true

require 'command_class'

module Authentication
  module AuthnK8s

    class K8sAuthenticatorData
      attr_reader :service_account_token, :ca_certificate, :k8s_api_url, :json_data

      def initialize(json_data)
        @json_data = json_data

        @service_account_token = json_data['service-account-token']
        @ca_certificate = json_data['ca-cert']
        @k8s_api_url = json_data['api-url']
      end

      # TODO Validation: Need to validate json_data contents and each individual variable
    end

    class InitializeK8sAuth
      extend CommandClass::Include
      
      def AUTHENTICATOR_NAME
        "authn-k8s"
      end

      command_class(
        dependencies: {
          conjur_ca_repo: Repos::ConjurCA,
          secret: Secret
        },
        inputs: %i[conjur_account service_id auth_data]
      ) do
        def call
          Repos::ConjurCA.create("%s:webservice:conjur/%s/%s" % [ @conjur_account, AUTHENTICATOR_NAME, @service_id ] )

          unless @auth_data.nil?
            @auth_data.json_data.each {|key, value| @secret.create(resource_id: variable_id("kubernetes/%s" % key), value: value) }
          end
        rescue => e
          raise e
        end

        private

        # TODO Should this go in its own module so each auth initializer can share it?
        def variable_id(variable_name)
          policy_branch = "conjur/%s/%s" % [ AUTHENTICATOR_NAME, @service_id ]
          "%s:variable:%s/%s" % [ @conjur_account, policy_branch, variable_name ] 
        end
      end
    end

  end
end
