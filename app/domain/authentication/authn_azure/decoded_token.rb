module Authentication
  module AuthnAzure

    class DecodedToken

      XMS_MIRID_TOKEN_CLAIM_NAME = "xms_mirid".freeze
      OID_TOKEN_CLAIM_NAME       = "oid".freeze

      def initialize(decoded_token_hash:, logger:)
        @decoded_token_hash = decoded_token_hash
        @logger = logger
        validate
      end

      def xms_mirid
        @xms_mirid ||= token_claim_value(XMS_MIRID_TOKEN_CLAIM_NAME)
      end

      def oid
        @oid ||= token_claim_value(OID_TOKEN_CLAIM_NAME)
      end

      private

      def validate
        validate_token_claim_exists(XMS_MIRID_TOKEN_CLAIM_NAME)
        validate_token_claim_exists(OID_TOKEN_CLAIM_NAME)
      end

      def validate_token_claim_exists(claim_name)
        @logger.debug(
          LogMessages::Authentication::AuthnAzure::ValidatingTokenClaimExists.new(
            claim_name
          )
        )
        if @decoded_token_hash[claim_name].to_s.empty?
          raise Errors::Authentication::Jwt::TokenClaimNotFoundOrEmpty, claim_name
        end
      end

      def token_claim_value(claim_name)
        token_claim_value = @decoded_token_hash[claim_name]
        @logger.debug(
          LogMessages::Authentication::Jwt::ExtractedClaimFromToken.new(
            claim_name,
            token_claim_value
          )
        )
        token_claim_value
      end
    end
  end
end
