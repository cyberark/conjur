# frozen_string_literal: true

module Authentication
  module AuthnAzure

    class DecodedToken

      XMS_MIRID_TOKEN_CLAIM_NAME = "xms_mirid"
      OID_TOKEN_CLAIM_NAME       = "oid"

      attr_reader :xms_mirid, :oid

      def initialize(decoded_token_hash:, logger:)
        @decoded_token_hash = decoded_token_hash
        @logger = logger

        @xms_mirid = token_claim_value(XMS_MIRID_TOKEN_CLAIM_NAME)
        @oid = token_claim_value(OID_TOKEN_CLAIM_NAME)
      end

      private

      def token_claim_value(token_claim)
        token_claim_path = (token_claim.split('/'))
        token_claim_value = @decoded_token_hash.dig *token_claim_path

        unless token_claim_value
          raise Errors::Authentication::Jwt::TokenClaimNotFoundOrEmpty, token_claim
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
