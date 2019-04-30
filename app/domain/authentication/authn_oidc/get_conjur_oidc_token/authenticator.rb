require 'command_class'

module Authentication
  module AuthnOidc
    module GetConjurOidcToken
      class OIDCAuthenticationError < RuntimeError;
      end

      Authenticator = CommandClass.new(
        dependencies: {
        },
        inputs: %i(input oidc_id_token_details)
      ) do

        def call
          validate_id_token_claims
          validate_user_info
          # TODO: validate_nonce
          true
        end

        private

        def validate_id_token_claims
          expected = { client_id: @oidc_id_token_details.client_id, issuer: @oidc_id_token_details.issuer } # , nonce: 'nonce'}
          @oidc_id_token_details.id_token.verify!(expected)
        rescue OpenIDConnect::ResponseObject::IdToken::InvalidToken => e
          raise OIDCAuthenticationError, e.message
        end

        def validate_user_info
          raise OIDCAuthenticationError, subject_err_msg unless valid_subject?
          raise OIDCAuthenticationError, no_username_err_msg unless user_info.preferred_username
        end

        def user_info
          @oidc_id_token_details.user_info
        end

        def valid_subject?
          user_info.sub == id_token_subject
        end

        def id_token_subject
          @oidc_id_token_details.id_token.sub
        end

        def service
          @service ||= Resource["#{@input.account}:webservice:conjur/#{@input.authenticator_name}/#{@input.service_id}"]
        end

        def no_username_err_msg
          "username not found in OIDC access token"
        end

        def subject_err_msg
          "User info subject [#{user_info.sub}] and id token subject " \
            "[#{id_token_subject}] are not equal"
        end
      end
    end
  end
end