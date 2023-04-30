
module HostValidator
  extend ActiveSupport::Concern
  def validate_conjur_account(account)
      if %w[conjur cucumber rspec].exclude?(account)
        logger.error(
          Errors::Authorization::EndpointNotVisibleToRole.new(
            "Account is: #{account}. Should be one of the following: [conjur cucumber rspec]"
          )
        )
        raise ApplicationController::Forbidden
      end
  end

  def is_role_member_of_group(account, role_id, group_name)
    role = Role[account + group_name]
    unless role&.ancestor_of?(role = Role[role_id])
      return false
    end
    return true
  end

  def validate_conjur_admin_group(account)
    unless is_role_member_of_group(account, current_user.id, ':group:Conjur_Cloud_Admins')
      logger.error(
        Errors::Authorization::EndpointNotVisibleToRole.new(
          "Current user role is: #{current_user.id}. should be member of: \"group:Conjur_Cloud_Admins\""
        )
      )
      raise ApplicationController::Forbidden
    end
  end

  def verify_edge_host(options)
    validate_conjur_account(options[:account])
    msg = ""
    raise_excep = false
    if current_user.kind != 'host'
      raise_excep = true
      msg = "User kind is: #{current_user.kind}. Should be: 'host'"
    elsif current_user.role_id.exclude?("host:edge/edge")
      raise_excep = true
      msg = "Role is: #{current_user.role_id}. Should include: 'host:edge/edge'"
    else
      role = Role[options[:account] + ':group:edge/edge-hosts']
      unless role&.ancestor_of?(current_user)
        raise_excep = true
        msg = "Curren user is: #{current_user}. should be member of #{role}"
      end
    end

    if raise_excep
      logger.error(
        Errors::Authorization::EndpointNotVisibleToRole.new(
          msg
        )
      )
      raise ApplicationController::Forbidden
    end
  end
end

