module Authentication
  module AuthnOidc
    class UserDetails
      attr_reader :id_token, :user_info, :client_id, :issuer

      def initialize(id_token:, user_info:, client_id:, issuer:)
        # TODO: either this class should be renamed, or we figure out a refactor
        # that brings this data to the authenticator in a different way.
        
        @id_token = id_token
        @user_info = user_info
        @client_id = client_id
        @issuer = issuer
      end
    end
  end
end
