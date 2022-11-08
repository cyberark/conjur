# frozen_string_literal: true

module Authentication
  module AuthnOidc
    module V2
      class Logout
        def initialize(
          authenticator:,
          client: Authentication::AuthnOidc::V2::Client,
          logger: Rails.logger
        )
          @authenticator = authenticator
          @client = client.new(authenticator: authenticator)
          @logger = logger
        end

        def callback(args)
          @client.logout(refresh_token: args[:refresh_token], nonce: args[:nonce])
        end
      end
    end
  end
end
