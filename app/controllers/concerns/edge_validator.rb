# frozen_string_literal: true

module EdgeValidator
  extend ActiveSupport::Concern

  def verify_edge_host(options)
    msg = ""
    raise_excep = false

    validate_account(options[:account])

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

  def validate_scope(limit, offset)
    if offset || limit
      # 'limit' must be an integer greater than 0 and less than 2000 if given
      if limit && (!numeric?(limit) || limit.to_i <= 0 || limit.to_i > 2000)
        raise ArgumentError, "'limit' contains an invalid value. 'limit' must be a positive integer and less than 2000"
      end
      # 'offset' must be an integer greater than or equal to 0 if given
      if offset && (!numeric?(offset) || offset.to_i.negative?)
        raise ArgumentError, "'offset' contains an invalid value. 'offset' must be an integer greater than or equal to 0."
      end
    end
  end

end
