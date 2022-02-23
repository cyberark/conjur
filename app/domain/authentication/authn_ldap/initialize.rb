# frozen_string_literal: true

require 'command_class'

module Authentication
  module AuthnLdap

    # Secrets used when persisting a LDAP authenticator
    class LdapAuthenticatorData
      include ActiveModel::Validations
      attr_reader :tls_ca_cert, :bind_password, :annotations, :json_data

      def initialize(json_data)
        @json_data = json_data
        @bind_password = @json_data['bind-password']
        @tls_ca_cert = @json_data['tls-ca-cert']
        @annotations = @json_data['annotations']

        # LDAP doesn't work like other auths, the annotations key doesn't represent a variable so remove it
        @json_data.delete('annotations')
      end

      def auth_name
        "authn-ldap"
      end

      def json_parameters
        [ 'bind-password', 'tls-ca-cert' ]
      end

      validates(
        :json_data,
        json: true
      )

      # Regex below is based off of the RFC which formally defines PEM format, we only accept PEM
      # not DER because binary data is difficult to handle well in JSON.
      # https://www.rfc-editor.org/rfc/rfc7468
      validates(
        :tls_ca_cert,
        format: {
          with: %r{(((-+)BEGIN [A-Z ]+(-+)\n)(?:[A-Za-z\d+/]{4})*\n((-+)END [A-Z ]+(-+))\n?)},
          message: "Certificate must be in PEM format"
        },
        presence: true
      )

      validates(
        :bind_password,
        presence: true
      )

      validates(
        :annotations,
        presence: true
      )
    end

    # Performs setup for newly persisted LDAP authenticators
    class InitializeLdapAuth
      extend CommandClass::Include
      
      command_class(
        dependencies: {
          conjur_ca_repo: Repos::ConjurCA,
          secret: Secret
        },
        inputs: %i[conjur_account service_id auth_data]
      ) do
        def call
          ['tls-ca-cert', 'bind-password'].each do |key|
            policy_branch = format("conjur/%s/%s", @auth_data.auth_name, @service_id)
            variable_id = format("%s:variable:%s/%s", @conjur_account, policy_branch, key)

            @secret.create(resource_id: variable_id, value: @auth_data.json_data[key])
          end
        end
      end
    end

  end
end
