# frozen_string_literal: true

require 'command_class'
require './app/db/repository/authenticator_repository'

module Authentication
  module AuthnOidc
    module V2
      module Commands
        ListProviders ||= CommandClass.new(
          dependencies: {
            json_lib: JSON,
            logger: Rails.logger
          },
          inputs: %i[message]
        ) do
          def call
            params = @json_lib.parse(@message)
            @logger.debug("#{self.class}##{__method__} - #{params}")
            (account = params.delete("account")) || raise("'account' is required")

            authenticators = DB::Repository::AuthenticatorRepository.new(
                data_object: Authentication::AuthnOidc::V2::DataObjects::Authenticator,
                logger: @logger
              ).find_all(
                account: account,
                type: 'authn-oidc'
              )
            @logger.debug("#{self.class}##{__method__} - #{authenticators.inspect}")
            Authentication::AuthnOidc::V2::Views::ProviderContext.new(
              logger: @logger
            ).call(
              authenticators: authenticators
            )
          end
        end
      end
    end
  end
end
