module Authentication
  module AuthnOidc
    module GetConjurOidcToken
      class IDTokenDetails
        attr_reader :id_token, :user_info, :client_id, :issuer, :expiration_time

        def initialize(id_token:, user_info:, client_id:, issuer:, expiration_time:)
          # TODO: either this class should be renamed, or we figure out a refactor
          # that brings this data to the authenticator in a different way.

          @id_token = id_token
          @user_info = user_info
          @client_id = client_id
          @issuer = issuer
          @expiration_time = expiration_time
        end
      end
    end
  end
end
