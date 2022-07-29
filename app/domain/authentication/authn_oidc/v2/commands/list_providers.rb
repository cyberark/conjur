# frozen_string_literal: true

require 'command_class'
require './app/db/repository/authenticator_repository'

module Authentication
  module AuthnOidc
    module V2
      module Commands
        ListProviders ||= CommandClass.new(
          dependencies: {
            json_lib: JSON
          },
          inputs: %i[message]
        ) do
          def call
            params = @json_lib.parse(@message)
            (account = params.delete("account")) || raise("'account' is required")
            Authentication::AuthnOidc::V2::Views::ProviderContext.new.call(
              authenticators: DB::Repository::AuthenticatorRepository.new(
                data_object:  Authentication::AuthnOidc::V2::DataObjects::Authenticator
              ).find_all(
                account: account,
                type: 'authn-oidc'
              )
            )
          end
        end
      end
    end
  end
end
