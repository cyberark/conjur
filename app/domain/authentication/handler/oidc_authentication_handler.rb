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
        json: ::JSON::JWT,
        oidc_util: nil
      )
        super(
          authenticator_repository: authenticator_repository,
          token_factory: token_factory,
          role_repository_class: role_repository_class,
          resource_repository_class: resource_repository_class
        )

        @oidc_util = oidc_util
        @json = json
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

        "#{oidc_util(authenticator).discovery_information.authorization_endpoint}?#{params}"
      end

      protected

      def validate_parameters_are_valid(authenticator, parameters)
        super(authenticator, parameters)

        raise Errors::Authentication::AuthnOidc::StateMismatch unless parameters[:state] == authenticator.state
      end

      def extract_identity(authenticator, params)
        oidc_util = oidc_util(authenticator)

        if authenticator.version == Authenticator::OidcAuthenticator::AUTH_VERSION_1
          return v1_extract_identity(authenticator, oidc_util, params)
        end

        v2_extract_identity(authenticator, oidc_util, params)
      end

      def type
        'oidc'
      end

      def oidc_util(authenticator)
        @oidc_util ||= Authentication::Util::OidcUtil.new(authenticator: authenticator)
      end

      private

      def v1_extract_identity(authenticator, oidc_util, params)
        id_token = Hash[URI.decode_www_form(params[:credentials])].fetch("id_token", "")
        raise Errors::Authentication::RequestBody::MissingRequestParam, "id_token" unless id_token && !id_token.strip.empty?

        jwks = oidc_util.discovery_information.jwks
        decoded_id_token = @json.decode(id_token, jwks)
        decoded_id_token.verify!(jwks)

        decoded_id_token[authenticator.claim_mapping]
      end

      def v2_extract_identity(authenticator, oidc_util, params)
        oidc_client = oidc_util.client
        oidc_client.authorization_code = params[:code]
        nonce = authenticator.nonce
        id_token = oidc_client.access_token!(scope: true, client_auth_method: :basic, nonce: nonce).id_token
        decoded_id_token = oidc_util.decode_token(id_token)
        decoded_id_token.verify!(
          issuer: authenticator.provider_uri,
          client_id: authenticator.client_id,
          nonce: nonce
        )

        decoded_id_token.raw_attributes.with_indifferent_access[authenticator.claim_mapping]
      rescue OpenIDConnect::ValidationFailed => e
        raise Errors::Authentication::AuthnOidc::TokenVerificationFailed, e.message
      end
    end
  end
end
