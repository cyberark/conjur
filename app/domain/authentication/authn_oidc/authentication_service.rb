require 'uri'
require 'openid_connect'
require 'command_class'

# TODO create this directly inside strategy
# add it to Authenticator to make it accessible
#
# Update name AuthenticationService
#
# Update user_details to call
#
module Authentication
  module AuthnOidc
    GetUserDetails = CommandClass.new(
      dependencies: {fetch_secrets: FetchRequiredSecrets.new},
      inputs: [:request_body, :service_id, :conjur_account]
    ) do

      # @return [AuthOidc::UserDetails] containing decoded id token, user info,
      # and issuer
      def call
        set_client_authorization_code
        set_client_host
        user_details
      end

      private

      def set_client_authorization_code
        oidc_client.authorization_code = authorization_code
      end

      def set_client_host
        oidc_client.host = URI.parse(provider_uri).host
      end

      def user_details
        UserDetails.new(
          id_token: id_toden,
          user_info: user_info,
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
        "#{@conjur_account}:variable:#{@service_id}/#{var_name}"
      end

      def client_id
        @client_id ||= secret_value('client-id')
      end

      def client_secret
        @client_secret ||= secret_value('client-secret')
      end

      def provider_uri
        @provider_uri ||= secret_value('provider_uri')
      end

      def secret_value(var_name)
        required_secrets[variable_id(var_name)]
      end

      # TODO: disable_ssl_verification should not run in production
      def discovered_resource
        return @discovered_resource if @discovered_resource
        disable_ssl_verification
        @discovered_resource ||= OpenIDConnect::Discovery::Provider::Config.discover!(provider_uri)
      end

      # TODO: Delete disable ssl action after fix OpenID connect to support
      # self sign ceritficate
      def disable_ssl_verification
        OpenIDConnect.http_config do |config|
          config.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
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
