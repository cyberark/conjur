module Authentication
  module AuthnOidc
    class UserDetails
      attr_reader :id_token, :user_info, :issuer

      def initialize(id_token:, user_info:, issuer:)
        @id_token = id_token
        @user_info = user_info
        @issuer = issuer
      end
    end
  end
end
