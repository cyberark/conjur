module Authentication
  module AuthnOidc
    class OidcToken
      attr_reader :id_token_encrypted, :user_info, :expiration_time

      def initialize(id_token_encrypted:, user_info:, expiration_time:)
        @id_token_encrypted = id_token_encrypted
        @user_info = user_info
        @expiration_time = expiration_time
      end
    end
  end
end
