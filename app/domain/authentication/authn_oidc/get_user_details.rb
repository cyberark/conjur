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

    GetUserDetails = CommandClass.new(
      dependencies: { fetch_secrets: ::Conjur::FetchRequiredSecrets.new },
      inputs: %i(request_body service_id conjur_account)
    ) do

      # @return [AuthOidc::UserDetails] containing decoded id token, user info,
      # and issuer
      def call
        configure_oidc_client
        user_details
      rescue OpenIDConnect::HttpError => e
        # adding the reponse body as it includes additional error information
        raise e, "#{e.message}, #{e.response.body}", e.backtrace if e.response
        raise e
      end

      private

      def configure_oidc_client
        oidc_client.authorization_code = authorization_code
        oidc_client.host = URI.parse(provider_uri).host
      end

      def user_details
        UserDetails.new(
          id_token: id_token,
          user_info: user_info,
          client_id: client_id,
          issuer: discovered_resource.issuer
        )
      end

      # TODO: capture exception: JSON::JWK::Set::KidNotFound and try refresh
      # signing keys
      def id_token
        OpenIDConnect::ResponseObject::IdToken.decode(
          access_token.id_token, discovered_resource.jwks
        )
      end

      def user_info
        access_token.userinfo!
      end

      def access_token
        @access_token ||= oidc_client.access_token!
      rescue Rack::OAuth2::Client::Error => e
        raise OIDCAuthenticationError, e.message
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
        @client_id ||= secret_value('client-id')
      end

      def client_secret
        @client_secret ||= secret_value('client-secret')
      end

      def provider_uri
        @provider_uri ||= secret_value('provider-uri')
      end

      def secret_value(var_name)
        required_secrets[variable_id(var_name)]
      end

      def discovered_resource
        @discovered_resource ||= OpenIDConnect::Discovery::Provider::Config.discover!(provider_uri)
      end

      def oidc_client
        @oidc_client ||= OpenIDConnect::Client.new(
          identifier: client_id,
          secret: client_secret,
          redirect_uri: redirect_uri,
          token_endpoint: discovered_resource.token_endpoint,
          userinfo_endpoint: discovered_resource.userinfo_endpoint
        )
      end
    end
  end
end
