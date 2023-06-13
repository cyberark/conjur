# frozen_string_literal: true

module AccountValidator
  extend ActiveSupport::Concern
  def validate_account(account)
    if %w[conjur cucumber rspec].exclude?(account)
      logger.error(
        Errors::Authorization::EndpointNotVisibleToRole.new(
          "Account is: #{account}. Should be one of the following: [conjur cucumber rspec]"
        )
      )
      raise ApplicationController::Forbidden
    end
  end
end
