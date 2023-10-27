# frozen_string_literal: true

module Authentication
  module AuthnOidc
    module V2
      class Strategy
        REQUIRED_PARAMS = %i[code nonce].freeze
        ALLOWED_PARAMS = (REQUIRED_PARAMS + %i[code_verifier]).freeze

        def initialize(
          authenticator:,
          client: Authentication::AuthnOidc::V2::Client,
          logger: Rails.logger
        )
          @authenticator = authenticator
          @client = client.new(authenticator: authenticator)
          @logger = logger

          @success = ::SuccessResponse
          @failure = ::FailureResponse
        end

        # rubocop:disable Lint/UnusedMethodArgument
        def callback(parameters:, request_body: nil)
          validate_parameters(parameters).bind do |params|
            validate_jwt_token(params).bind do |jwt_token|
              resolve_identity(jwt: jwt_token).bind do |identity|
                @success.new(
                  Authentication::Base::RoleIdentifier.new(
                    identifier: "#{@authenticator.account}:user:#{identity}"
                  )
                )
              end
            end
          end

        end
        # rubocop:enable Lint/UnusedMethodArgument

        # Called by status handler. This handles checking as much of the strategy
        # integrity as possible without performing an actual authentication.
        def verify_status
          @client.discover
        end

        private

        def validate_parameters(parameters)
          REQUIRED_PARAMS.each do |param|
            unless parameters[param].present?
              return @failure.new(
                "Missing parameter: '#{param}'",
                exception: Errors::Authentication::RequestBody::MissingRequestParam.new(
                  param.to_s
                ),
                status: :bad_request
              )
            end
          end
          @success.new(parameters.select {|item| ALLOWED_PARAMS.include?(item) } )
        end

        def validate_jwt_token(parameters)
          @client.callback_with_temporary_cert(
            code: parameters[:code],
            nonce: parameters[:nonce],
            code_verifier: parameters[:code_verifier],
            cert_string: @authenticator.ca_cert
          )
        end

        def resolve_identity(jwt:)
          identity = jwt.raw_attributes.with_indifferent_access[@authenticator.claim_mapping]
          return @success.new(identity) if identity.present?

          @failure.new(
            'Claim was not found',
            exception: Errors::Authentication::AuthnOidc::IdTokenClaimNotFoundOrEmpty.new(
              @authenticator.claim_mapping,
              'claim-mapping'
            ),
            status: :unauthorized
          )
        end
      end
    end
  end
end
