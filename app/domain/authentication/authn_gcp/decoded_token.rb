# frozen_string_literal: true

module Authentication
  module AuthnGcp

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

        initialize_required_claims
        initialize_optional_claims
      end

      private

      def initialize_required_claims
        @audience = required_token_claim_value(AUDIENCE_TOKEN_CLAIM_NAME)
        @service_account_id = required_token_claim_value(SUB_TOKEN_CLAIM_NAME)
        @service_account_email = required_token_claim_value(EMAIL_TOKEN_CLAIM_NAME)
      end

      def initialize_optional_claims
        @project_id = optional_token_claim_value(PROJECT_ID_TOKEN_CLAIM_NAME)
        @instance_name = optional_token_claim_value(INSTANCE_NAME_TOKEN_CLAIM_NAME)
      end

      def required_token_claim_value(required_token_claim)
        required_token_claim_value = token_claim_value(required_token_claim)

        if required_token_claim_value.nil? || required_token_claim_value.empty?
          raise Errors::Authentication::Jwt::TokenClaimNotFoundOrEmpty, required_token_claim
        end

        log_claim_extracted_from_token(required_token_claim, required_token_claim_value)

        required_token_claim_value
      end

      def optional_token_claim_value(optional_token_claim)
        optional_token_claim_value = token_claim_value(optional_token_claim)

        if optional_token_claim_value.nil? || optional_token_claim_value.empty?
          @logger.debug(LogMessages::Authentication::Jwt::OptionalTokenClaimNotFoundOrEmpty.new(optional_token_claim))
        else
          log_claim_extracted_from_token(optional_token_claim, optional_token_claim_value)
        end

        optional_token_claim_value
      end

      def token_claim_value(token_claim)
        token_claim_path = token_claim.split('/')
        @decoded_token_hash.dig(*token_claim_path)
      end

      def log_claim_extracted_from_token(token_claim, token_claim_value)
        @logger.debug(
          LogMessages::Authentication::Jwt::ExtractedClaimFromToken.new(
            token_claim,
            token_claim_value
          )
        )
      end
    end
  end
end