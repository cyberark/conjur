module Authentication
  module AuthnAzure

    class DecodedToken

      XMS_MIRID_TOKEN_FIELD_NAME = "xms_mirid".freeze
      OID_TOKEN_FIELD_NAME       = "oid".freeze

      def initialize(decoded_token_hash:, logger:)
        @decoded_token_hash = decoded_token_hash
        @logger = logger
        validate
      end

      def xms_mirid
        @xms_mirid ||= token_field_value(XMS_MIRID_TOKEN_FIELD_NAME)
      end

      def oid
        @oid ||= token_field_value(OID_TOKEN_FIELD_NAME)
      end

      private

      def validate
        validate_token_field_exists(XMS_MIRID_TOKEN_FIELD_NAME)
        validate_token_field_exists(OID_TOKEN_FIELD_NAME)
      end

      def validate_token_field_exists(field_name)
        @logger.debug(
          LogMessages::Authentication::AuthnAzure::ValidatingTokenFieldExists.new(
            field_name
          )
        )
        if @decoded_token_hash[field_name].to_s.empty?
          raise Errors::Authentication::Jwt::TokenFieldNotFoundOrEmpty, field_name
        end
      end

      def token_field_value(field_name)
        token_field_value = @decoded_token_hash[field_name]
        @logger.debug(
          LogMessages::Authentication::Jwt::ExtractedClaimFromToken.new(
            field_name,
            token_field_value
          )
        )
        token_field_value
      end
    end
  end
end
