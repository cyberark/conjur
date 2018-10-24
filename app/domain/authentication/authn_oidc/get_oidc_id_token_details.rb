require 'uri'
require 'openid_connect'
require 'command_class'
require 'conjur/fetch_required_secrets'

module Authentication
  module AuthnOidc

    # TODO: (later version) Fix CommandClass so we can add errors directly
    # inside of it
    #
    # TODO: list any OIDC or other errors here.  The errors are part of the
    # API.
    #
    # Errors from FetchRequiredSecrets
    #
    RequiredResourceMissing = ::Conjur::RequiredResourceMissing
    RequiredSecretMissing = ::Conjur::RequiredSecretMissing

    GetOidcIDTokenDetails = CommandClass.new(
      dependencies: {
        oidc_client_class: OidcClient,
        fetch_secrets: ::Conjur::FetchRequiredSecrets.new
      },
      inputs: %i(request_body service_id conjur_account)
    ) do

      # @return [AuthOidc::OidcIDTokenDetails] containing decoded id token, user info,
      # and issuer
      def call
        configure_oidc_client
        oidc_id_token_details
      rescue OpenIDConnect::HttpError => e
        # adding the reponse body as it includes additional error information
        raise e, "#{e.message}, #{e.response.body}", e.backtrace if e.response
        raise e
      end

      private

      def configure_oidc_client
        host = URI.parse(provider_uri).host
        oidc_client.configure(authorization_code: authorization_code, host: host)
      end

      def oidc_id_token_details
        OidcIDTokenDetails.new(
          id_token: oidc_client.id_token,
          user_info: oidc_client.user_info,
          client_id: client_id,
          issuer: oidc_client.issuer,
          expiration_time: expiration_time
        )
      end

      # todo: move inside OidcClient
      def expiration_time
        oidc_client.id_token.raw_attributes["exp"]
      end

      def decoded_body
        @decoded_body ||= URI.decode_www_form(@request_body)
      end

      def redirect_uri
        @redirect_uri ||= decoded_body.assoc('redirect_uri').last
      end

      def authorization_code
        @authorization_code ||= decoded_body.assoc('code').last
      end

      def required_secrets
        @required_secrets ||= @fetch_secrets.(resource_ids: required_resource_ids)
      end

      def required_resource_ids
        required_variable_names.map { |var_name| variable_id(var_name) }
      end

      def required_variable_names
        %w(client-id client-secret provider-uri)
      end

      # TODO: for next version: push this logic into a reusable value object
      #
      # NOTE: technically this should be memoized by argument (through memoist
      # gem, eg) but the calc is so simple it doesn't matter.
      def variable_id(var_name)
        "#{@conjur_account}:variable:conjur/authn-oidc/#{@service_id}/#{var_name}"
      end

      def client_id
        secret_value('client-id')
      end

      def client_secret
        secret_value('client-secret')
      end

      def provider_uri
        secret_value('provider-uri')
      end

      def secret_value(var_name)
        required_secrets[variable_id(var_name)]
      end

      def oidc_client
        @oidc_client ||= @oidc_client_class.new(
          client_id: client_id,
          client_secret: client_secret,
          redirect_uri: redirect_uri,
          provider_uri: provider_uri
        )
      end
    end
  end
end
