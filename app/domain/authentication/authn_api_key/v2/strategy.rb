# frozen_string_literal: true

# Conjur API authenticator
module Authentication
  module AuthnApiKey
    module V2
      class Strategy

        # This authenticator is a bit different because it validates based on the
        # information stored in the Conjur database. As such, Role and Credential
        # are made available.  Longer term, they should probably become part of this
        # authenticator.
        def initialize(authenticator:, logger: Rails.logger, credentials: ::Credentials, role: ::Role)
          @authenticator = authenticator
          @logger = logger
          @credentials = credentials
          @role = role
          @success = ::SuccessResponse
          @failure = ::FailureResponse
        end

        def callback(request_body:, parameters:)
          # TODO: Check that `id` is present in the parameters list

          role_id = parameters['id']
          api_key = request_body

          role_id = if role_id.match?(/^host\/./)
            id = role_id.split('/')[1..-1].join
            "#{@authenticator.account}:host:#{id}"
          else
            "#{@authenticator.account}:user:#{role_id}"
          end

          role_identifier = Authentication::Base::RoleIdentifier.new(
            role_identifier: role_id
          )

          if @role[role_id].nil?
            return @failure.new(
              role_identifier,
              exception: Errors::Authentication::Security::RoleNotFound.new(role_id)
            )
          end

          role_credentials = @credentials[role_id]
          if role_credentials.nil?
            return @failure.new(
              role_identifier,
              exception: Errors::Authentication::RoleHasNoCredentials.new(role_id)
            )
          end

          return @success.new(role_identifier) if role_credentials.valid_api_key?(api_key)

          @failure.new(
            role_identifier,
            exception: Errors::Conjur::ApiKeyNotFound.new(role_id)
          )
        end

        # Called by status handler. This handles checking as much of the strategy
        # integrity as possible without performing an actual authentication.
        def verify_status
          true
        end
      end
    end
  end
end
