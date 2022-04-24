# frozen_string_literal: true

require 'command_class'

module Authentication
  module AuthnK8s
    # Secrets used when persisting a K8s authenticator
    class AuthenticatorData
      include ActiveModel::Validations
      attr_reader :service_account_token, :ca_certificate, :k8s_api_url, :json_data

      def initialize(json_data)
        @json_data = json_data
        
        @service_account_token = parameters['service-account-token']
        @ca_certificate = parameters['ca-cert']
        @k8s_api_url = parameters['api-url']
      end

      def auth_name
        "authn-k8s"
      end

      def json_parameter_names
        [ 'service-account-token', 'ca-cert', 'api-url' ]
      end

      def parameters
        @json_data.select {|key, value| key != 'service-id'}
      end

      validates(
        :json_data,
        json: true
      )

      validates(
        :service_account_token,
        presence: true
      )

      # Regex below is based off of the RFC which formally defines PEM format, we only accept PEM
      # not DER because binary data is difficult to handle well in JSON.
      # https://www.rfc-editor.org/rfc/rfc7468
      validates(
        :ca_certificate,
        format: {
          with: %r{(((-+)BEGIN [A-Z ]+(-+)\n)(?:[A-Za-z\d+/]{4})*\n((-+)END [A-Z ]+(-+))\n?)},
          message: "Certificate must be in PEM format"
        },
        presence: true
      )

      validates(
        :k8s_api_url,
        url: true,
        presence: true
      )
    end

    # Performs setup for newly persisted k8s authenticators
    class InitializeK8sAuth
      extend CommandClass::Include
      include AuthorizeResource
      
      command_class(
        dependencies: {
          conjur_ca_repo: Repos::ConjurCA,
          secret: Secret
        },
        inputs: %i[conjur_account service_id auth_data current_user]
      ) do
        def call
          @auth_data.parameters&.each do |key, value|
            policy_branch = "conjur/#{@auth_data.auth_name}/#{@service_id}"
            variable_id = "#{@conjur_account}:variable:#{policy_branch}/kubernetes/#{key}"

            auth(@current_user, :update, Resource[variable_id])
            @secret.create(resource_id: variable_id, value: value)
          end

          ca_repo_id = "#{@conjur_account}:webservice:conjur/#{@auth_data.auth_name}/#{@service_id}"
          auth(@current_user, :update, Resource[ca_repo_id])
          @conjur_ca_repo.create(ca_repo_id)
        end
      end
    end

  end
end
