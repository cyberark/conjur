module Authentication
  module AuthnOidc
    class OidcConjurToken
      attr_reader :id_token_encrypted, :user_name, :expiration_time

      def initialize(id_token_encrypted:, user_name:, expiration_time:)
        @id_token_encrypted = id_token_encrypted
        @user_name = user_name
        @expiration_time = expiration_time
      end
    end
  end
end
