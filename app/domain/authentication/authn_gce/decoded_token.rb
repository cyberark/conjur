# frozen_string_literal: true

module Authentication
  module AuthnGce

    class DecodedToken

      PROJECT_ID_TOKEN_CLAIM_NAME = "google/compute_engine/project_id"
      INSTANCE_NAME_TOKEN_CLAIM_NAME = "google/compute_engine/instance_name"
      SUB_TOKEN_CLAIM_NAME = "sub"
      EMAIL_TOKEN_CLAIM_NAME = "email"
      AUDIENCE_TOKEN_CLAIM_NAME = "aud"

      attr_reader :project_id, :instance_name, :service_account_id, :service_account_email, :audience

      def initialize(decoded_token_hash:, logger:)
        @decoded_token_hash = decoded_token_hash
        @logger = logger

        @project_id = token_claim_value(PROJECT_ID_TOKEN_CLAIM_NAME)
        @instance_name = token_claim_value(INSTANCE_NAME_TOKEN_CLAIM_NAME)
        @service_account_id = token_claim_value(SUB_TOKEN_CLAIM_NAME)
        @service_account_email = token_claim_value(EMAIL_TOKEN_CLAIM_NAME)
        @audience = token_claim_value(AUDIENCE_TOKEN_CLAIM_NAME)
      end

      private

      def token_claim_value(token_claim)
        token_claim_path = (token_claim.split('/'))
        token_claim_value = @decoded_token_hash.dig *token_claim_path

        unless token_claim_value
          raise Errors::Authentication::AuthnGce::TokenClaimNotFoundOrEmpty, token_claim
        end

        @logger.debug(
          LogMessages::Authentication::Jwt::ExtractedClaimFromToken.new(
            token_claim,
            token_claim_value
          )
        )
        token_claim_value
      end
    end
  end
end
