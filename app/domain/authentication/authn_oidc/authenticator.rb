require 'command_class'

module Authentication
  module AuthnOidc
    class AuthenticationError < RuntimeError; end
    class NotFoundError < RuntimeError; end
    class OIDCConfigurationError < RuntimeError; end
    class OIDCAuthenticationError < RuntimeError; end

    # TODO: Should really have a verb name "Authenticate" since it's a command
    # object but we'll leave it like this for now for consistency
    #
    Authenticator = CommandClass.new(
      dependencies: {env: ENV},
      inputs: [:input, :user_details]
    ) do

      def call
        validate_id_token_claims
        validate_user_info
        true
      end

      private

      def validate_id_token_claims(id_token, client_id, issuer)
        expected = { client_id: client_id, issuer: issuer } # , nonce: 'nonce'}
        @user_details.id_token.verify!(expected)
      end

      def validate_user_info
        unless user_info.sub == id_token_subject
          raise OIDCAuthenticationError, "User info subject [#{user_info.sub}] and id token subject [#{id_token_subject}] are not equal"
        end

        # validate user_info was included in scope
        if user_info.preferred_username.nil?
          raise OIDCAuthenticationError, "[profile] is not included in scope of authorization code request"
        end
      end

      def user_info
        @user_details.user_info
      end

      def id_token_subject
        @user_details.id_token.sub
      end

      def authenticator_name
        @input.authenticator_name
      end

      def service_id
        @input.service_id
      end

      def conjur_account
        @input.account
      end

      def request_body
        @request_body ||= @input.request.body.read
      end

      def service
        @service ||= Resource["#{conjur_account}:webservice:conjur/#{authenticator_name}/#{service_id}"]
      end

      # NOTE: These can be removed since they're now handled by
      # `validate_security` in strategy
      #
      # def verify_service_enabled
      #   verify_service_exists

      #   raise OIDCConfigurationError, "#{authenticator_name}/#{service_id} not whitelisted in CONJUR_AUTHENTICATORS" unless authenticator_available?
      # end

      # def verify_service_exists
      #   raise OIDCConfigurationError, "Webservice [conjur/#{authenticator_name}/#{service_id}] not found in Conjur" unless service
      # end

      # def authenticator_available?
      #   conjur_authenticators = (@env['CONJUR_AUTHENTICATORS'] || '').split(',').map(&:strip)
      #   conjur_authenticators.include?("#{authenticator_name}/#{service_id}")
      # end
    end
  end
end
