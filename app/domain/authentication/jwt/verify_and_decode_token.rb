require 'jwt'

module Authentication
  module Jwt

    Err = Errors::Authentication::Jwt
    Log = LogMessages::Authentication::Jwt
    # Possible Errors Raised:
    # TokenExpired, TokenDecodeFailed, TokenVerifyFailed

    VerifyAndDecodeToken = CommandClass.new(
      dependencies: {
        jwt_decoder: JWT,
        logger:      Rails.logger
      },
      inputs:       %i(token_jwt verification_options)
    ) do

      def call
        verified_and_decoded_token
      end

      private

      def verified_and_decoded_token
        # @jwt_decoder.decode returns an array with one decoded token so we take the first object
        @decoded_token = @jwt_decoder.decode(
          @token_jwt,
          nil, # the key will be taken from options[:jwks] if present
          should_verify,
          @verification_options
        ).first.tap do
          @logger.debug(Log::TokenDecodeSuccess.new)
        end
      rescue JWT::ExpiredSignature
        raise Err::TokenExpired
      rescue JWT::DecodeError
        @logger.debug(Log::TokenDecodeFailed.new(e.inspect))
        raise Err::TokenDecodeFailed, e.inspect
      rescue => e
        raise Err::TokenVerifyFailed, e.inspect
      end

      def should_verify
        @should_verify ||= @verification_options && !@verification_options.empty?
      end
    end
  end
end
