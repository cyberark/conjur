require 'jwt'

module Authentication
  module Jwt

    # This class verifies and decodes a JWT token. It doesn't connect with the issuer
    # of the token for verification. If a token verification is needed, a verification_options
    # object should be provided with the JWKs & algorithms required for the verification.
    # In addition, if token claims need to be verified they should be specified in the verification_options.
    # For example:
    #     @verification_options = {
    #       algorithms: @algs,
    #       jwks: @jwks,
    #       verify_iss: true
    #       iss: https://token-issuer.com/
    #     }
    #
    # For more information on the verification and decode process: https://github.com/jwt/ruby-jwt
    VerifyAndDecodeToken = CommandClass.new(
      dependencies: {
        jwt_decoder: JWT,
        logger:      Rails.logger
      },
      inputs:       %i[token_jwt verification_options]
    ) do

      def call
        verified_and_decoded_token
      end

      private

      def verified_and_decoded_token
        return @verified_and_decoded_token if @verified_and_decoded_token

        # @jwt_decoder.decode returns an array with one decoded token so we take the first object
        @verified_and_decoded_token = @jwt_decoder.decode(
          @token_jwt,
          nil, # the key will be taken from options[:jwks] if present
          should_verify,
          @verification_options
        ).first

        @logger.debug(LogMessages::Authentication::Jwt::TokenDecodeSuccess.new)
        @verified_and_decoded_token
      rescue JWT::ExpiredSignature
        raise Errors::Authentication::Jwt::TokenExpired
      rescue JWT::DecodeError => e
        @logger.debug(LogMessages::Authentication::Jwt::TokenDecodeFailed.new(e.inspect))
        raise Errors::Authentication::Jwt::TokenDecodeFailed, e.inspect
      rescue => e
        raise Errors::Authentication::Jwt::TokenVerificationFailed, e.inspect
      end

      def should_verify
        @should_verify ||= @verification_options && !@verification_options.empty?
      end
    end
  end
end
