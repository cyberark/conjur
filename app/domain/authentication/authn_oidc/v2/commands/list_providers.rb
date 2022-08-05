# frozen_string_literal: true

require 'command_class'
require './app/db/repository/authenticator_repository'
require './app/domain/authentication/authn_oidc/v2/data_objects/authenticator'
require './app/domain/authentication/authn_oidc/v2/views/provider_context'
require './app/domain/authentication/authn_oidc/v2/client'

module Authentication
  module AuthnOidc
    module V2
      module Commands
        ListProviders ||= CommandClass.new(
          dependencies: {
            json_lib: JSON,
            logger: Rails.logger,
            authenticatorRepository: nil,
            provider: Authentication::AuthnOidc::V2::Views::ProviderContext.new()
          },
          inputs: %i[message]
        ) do
          def call
            params = @json_lib.parse(@message)
            @logger.debug("#{self.class}##{__method__} - #{params}")
            (account = params.delete("account")) || raise("'account' is required")
            authenticators = @authenticatorRepository.find_all(account: account, type: 'authn-oidc')
            @logger.debug("#{self.class}##{__method__} - #{authenticators.inspect}")
            @provider.call(
              authenticators: authenticators
            )
          end
        end
      end
    end
  end
end