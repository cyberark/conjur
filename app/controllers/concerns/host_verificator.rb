
module HostValidator
  extend ActiveSupport::Concern
  def validate_conjur_account(account)
      if %w[conjur cucumber rspec].exclude?(account)
        logger.error(
          Errors::Authorization::EndpointNotVisibleToRole.new(
            "Account is: #{account}. Should be one of the following: [conjur cucumber rspec]"
          )
        )
        raise Forbidden
      end
  end
  def validate_conjur_admin_group(account)
    role = Role[account + ':group:Conjur_Cloud_Admins']
    unless role&.ancestor_of?(current_user)
      logger.error(
        Errors::Authorization::EndpointNotVisibleToRole.new(
          "Curren user is: #{current_user}. should be member of #{role}"
        )
      )
    end
  end
end