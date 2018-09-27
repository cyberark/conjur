module Authentication
  module AuthnOidc
    class UserDetails
      attr_reader :id_token
      attr_reader :user_info

      def initialize(id_token, user_info)
        @id_token = id_token
        @user_info = user_info
      end
    end
  end
end
