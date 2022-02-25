require 'openid_connect'

module Authentication
  module AuthnOidc2
    class Mapper
      def initialize(allowable_roles:)
        @allowable_roles = allowable_roles
      end

      def call(identity:)
        identified_role = @allowable_roles.select do |role|
          role.id.split(':').last == identity
        end
        raise "#{identify} was not found as a valid authenticatable role" if identified_role.nil?

        identified_role
      end
    end

    class Callback
      REQUIRED_CONFIGURATION = %i[
        issuer_uri
        client_id
        client_secret
        redirect_uri
        claim_mapping
      ].freeze

      REQUIRED_PARAMS = %i[code state].freeze

      # The arguements `nonce` and `state` are included as arguements to simplify
      # testing and local development.
      def initialize(config:, nonce: SecureRandom.hex(16), state: SecureRandom.hex(16))
        validate_present(
          args: config,
          required_fields: REQUIRED_CONFIGURATION
        )
        @config = config
        @nonce = nonce
        @state = state
      end

      def discovery_information
        @discovery_information ||= ::OpenIDConnect::Discovery::Provider::Config.discover!(
          @config[:issuer_uri]
        )
      end

      # Verify required fields are present.
      # TODO: This should go somewhere upstream.
      def validate_present(args:, required_fields:)
        required_fields.each do |field|
          raise "#{field} is required" if args.fetch(field, '').empty?
        end
      end

      def redirect_uri
        [
          discovery_information.authorization_endpoint,
          {
            client_id: @config[:client_id],
            redirect_uri: @config[:redirect_uri],
            response_type: 'code',
            scope: ERB::Util.url_encode('openid profile email'),
            state: @state,
            nonce: @nonce
          }.map{|key, value| "#{key}=#{value}" }.join('&')
        ].join('?')
      end

      def client
        @client ||= begin
          issuer_uri = URI(@config[:issuer_uri])
          ::OpenIDConnect::Client.new(
            identifier: @config[:client_id],
            secret: @config[:client_secret],
            redirect_uri: @config[:redirect_uri],
            scheme: issuer_uri.scheme,
            host: issuer_uri.host,
            port: issuer_uri.port,
            authorization_endpoint: URI(discovery_information.authorization_endpoint).path,
            token_endpoint: URI(discovery_information.token_endpoint).path,
            userinfo_endpoint: URI(discovery_information.userinfo_endpoint).path,
            jwks_uri: URI(discovery_information.jwks_uri).path,
            end_session_endpoint: URI(discovery_information.end_session_endpoint).path
          )
        end
      end

      # Method to enable us to check if the initializer values are valid (as
      # best we can).
      def verify; end

      def call(params:)
        validate_present(
          args: params,
          required_fields: REQUIRED_PARAMS
        )

        raise 'State Mismatch' if params[:state] != @state

        client.authorization_code = params[:code]
        access_token = client.access_token!(
          scope: true,
          client_auth_method: :basic
        )
        id_token = access_token.id_token

        decoded_id_token = ::OpenIDConnect::ResponseObject::IdToken.decode(
          id_token,
          discovery_information.jwks
        )
        decoded_id_token.verify!(
          issuer: @config[:issuer_uri],
          client_id: @config[:client_id],
          nonce: @nonce
        )

        # TODO: Run full verification on JWT to ensure it has not expired, all other
        # claims are valid, etc.

        # Return error if claim mapping does not exist
        decoded_id_token.raw_attributes[@config[:claim_mapping].to_s]
      end
    end

    class Authenticator
      # We don't need the env during the authentication process
      def self.requires_env_arg?
        false
      end

      # We actually don't have any specific validations for OIDC. We only verify
      # that the ID token is valid but this is done while it is decoded (using
      # a third-party). However, we want to verify that we verify the token no
      # matter what so we run the validation again (even if it means that in most
      # cases we will perform this action twice).
      #
      # The method is still defined because we need `valid?` to exist on the Authenticator
      # class so it is a valid Authenticator class
      def valid?(input)
        # Authentication::AuthnOidc::UpdateInputWithUsernameFromIdToken.new.(
        #   authenticator_input: input
        # )
      end

      def status(authenticator_status_input:)
        # Authentication::AuthnOidc::ValidateStatus.new.(
        #   account: authenticator_status_input.account,
        #   service_id: authenticator_status_input.service_id
        # )
      end
    end
  end
end

# # Post '/authn-oidc(/:service_id)/:account/callback'
# module Authenticators
#   class AuthenticatorLoader
#     def initialize(role: ::Role, resource: ::Resource)
#       @role = role
#       @resource = resource
#     end

#     # Authenticators::AuthenticatorLoader.find returns a Struct representation
#     # of an OIDC Authenticator:
#     # Struct.new(:config, :authenticatable_roles)
#     def find(account:, type:, service_id: nil)
#       #   1. Verify account exists
#       #   2. Is Authenticator valid?
#       #     a. Does it exist?
#       #     b. Is it enabled?
#       #     c. Is it configured?
#       #   3. Gather all Variables from the desired authenticator
#     end
#   end
# end

# authenticator_configuration = Authenticators::AuthenticatorLoader.new.find(
#   account: params[:account],
#   service_id: params[:service_id],
#   type: 'authn-oidc'
# )

# Authenticator.new.call(
#   identity_resolver: Authentication::AuthnOidc2::IdentityResolver.new(
#     config: authenticator_configuration.config
#   ),
#   mapper: Authentication::AuthnOidc2::Mapper.new(
#     roles: authenticator_configuration.authenticatable_roles
#   ),
#   params: params
# )

# module Validations
#   class Cidr
#     def valid?(role:, ip:)
#       raise Errors::Authentication::InvalidOrigin unless role.valid_origin?(ip)
#     end
#   end
# end

# class Authenticator
#   def initialize(token_factory: ::TokenFactory)
#     @token_factory = token_factory
#   end

#   def call(account:, params:, identity_resolver:, mapper:)
#     role = mapper.call(
#       identity: identity_resolver.call(
#         params: params
#       )
#     )
#     Validations::Cidr.new.valid?(role: role, ip: request[:ip])

#     @token_factory.signed_token(
#       account: account,
#       username: role
#     )
#   end
# end

# # Stages:
# #   1. Verify account exists
# #   2. Is Authenticator valid?
# #     a. Does it exist?
# #     b. Is it enabled?
# #     c. Is it configured?
# #   3. Gather all Variables from the desired authenticator
# #   4. Pass variables and authentication load to Authenticator
# #   5. Extract identity (ensuring load is valid)
# #   6. Using authenticator identity, lookup identity in Conjur
# #   7. Verify Conjur identity can use this authenticator
# #   8. Verify valid CIDR range
# #   9. Return Conjur Auth token
