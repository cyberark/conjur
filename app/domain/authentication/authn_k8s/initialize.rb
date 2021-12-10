# frozen_string_literal: true

require 'command_class'

module Authentication
  module AuthnK8s

    class K8sAuthenticatorData
      include ActiveModel::Validations
      attr_reader :service_account_token, :ca_certificate, :k8s_api_url, :json_data

      def initialize(raw_post)
        unless raw_post.empty?
          @json_data = JSON.parse(raw_post)

          @service_account_token = @json_data['service-account-token']
          @ca_certificate = @json_data['ca-cert']
          @k8s_api_url = @json_data['api-url']
        end
      end

      def auth_name
        "authn-k8s"
      end

      def json_parameters
        [ 'service-account-token', 'ca-cert', 'api-url' ]
      end

      def json_present?
        @json_data.present?
      end

      validates(
        :json_data,
        json: true,
        if: :json_present?
      )

      validates(
        :service_account_token,
        presence: true,
        if: :json_present?
      )

      # Regex below is based off of the RFC which formally defines PEM format, we only accept PEM
      # not DER because binary data is difficult to handle well in JSON.
      # https://www.rfc-editor.org/rfc/rfc7468
      validates(
        :ca_certificate,
        format: {
          with: /(((-+)BEGIN [A-Z ]+(-+)\n)(?:[A-Za-z\d+\/]{4})*\n((-+)END [A-Z ]+(-+))\n?)/,
          message: "Certificate must be in PEM format"
        },
        presence: true,
        if: :json_present?
      )

      validates(
        :k8s_api_url,
        url: true,
        presence: true,
        if: :json_present?
      )
    end

    class InitializeK8sAuth
      extend CommandClass::Include
      
      command_class(
        dependencies: {
          conjur_ca_repo: Repos::ConjurCA,
          secret: Secret
        },
        inputs: %i[conjur_account service_id auth_data]
      ) do
        def call
          @conjur_ca_repo.create("%s:webservice:conjur/%s/%s" % [ @conjur_account, @auth_data.auth_name, @service_id ] )

          unless @auth_data.json_data.nil?
            @auth_data.json_data.each {|key, value| @secret.create(resource_id: variable_id("kubernetes/%s" % key), value: value) }
          end
        rescue => e
          raise e
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
end
