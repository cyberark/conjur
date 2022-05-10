require 'openid_connect'
require_relative '../../../models/authenticator/oidc_authenticator'

module Authentication
  module Handler
    class OidcAuthenticationHandler < AuthenticationHandler
      def initialize(
        authenticator_repository: ::DB::Repository::AuthenticatorRepository.new,
        token_factory: TokenFactory.new,
        role_repository_class: ::Role,
        resource_repository_class: ::Resource,
        oidc_util: nil
      )
        super(
          authenticator_repository: authenticator_repository,
          token_factory: token_factory,
          role_repository_class: role_repository_class,
          resource_repository_class: resource_repository_class
        )

        @oidc_util = oidc_util
      end

      def generate_login_url(authenticator)
        params = {
          client_id: authenticator.client_id,
          response_type: authenticator.response_type,
          scope: ERB::Util.url_encode(authenticator.scope),
          state: authenticator.state,
          nonce: authenticator.nonce,
          redirect_uri: ERB::Util.url_encode(authenticator.redirect_uri)
        }.map { |key, value| "#{key}=#{value}" }.join("&")

        return "#{oidc_util(authenticator).discovery_information.authorization_endpoint}?#{params}"

      end

      protected

      def validate_parameters_are_valid(authenticator, parameters)
        super(authenticator, parameters)

        raise "State Mismatch" unless parameters[:state] == authenticator.state
      end

      def extract_identity(authenticator, params)
        oidc_util = oidc_util(authenticator)

        if authenticator.version == Authenticator::OidcAuthenticator::AUTH_VERSION_1
          return v1_extract_identity(authenticator, oidc_util, params)
        end

        return v2_extract_identity(authenticator, oidc_util, params)
      end

      def type
        return 'oidc'
      end

      def oidc_util(authenticator)
        @oidc_util ||= Authentication::Util::OidcUtil.new(authenticator: authenticator)
      end

      private

      def v1_extract_identity(authenticator, oidc_util, params)
        id_token = Hash[URI.decode_www_form(params[:credentials])].fetch("id_token", "")
        raise Errors::Authentication::RequestBody::MissingRequestParam, "id_token" unless id_token != ""

        decoded_id_token = JSON::JWT.decode(id_token, oidc_util.discovery_information.jwks)
        decoded_id_token.verify!(oidc_util.discovery_information.jwks)

        return decoded_id_token[authenticator.claim_mapping]
      end

      def v2_extract_identity(authenticator, oidc_util, params)
        oidc_util.client.authorization_code = params[:code]
        id_token = oidc_util.client.access_token!(scope: true, client_auth_method: :basic, nonce: authenticator.nonce).id_token
        decoded_id_token = oidc_util.decode_token(id_token)
        decoded_id_token.verify!(
          issuer: authenticator.provider_uri,
          client_id: authenticator.client_id,
          nonce: authenticator.nonce
        )

        Logger.new(STDOUT).info(decoded_id_token.inspect)
        Logger.new(STDOUT).info(decoded_id_token.raw_attributes.inspect)

        return decoded_id_token.raw_attributes[authenticator.claim_mapping]
      end
    end
  end
end