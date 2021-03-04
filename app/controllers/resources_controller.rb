# frozen_string_literal: true

class ResourcesController < RestController
  include FindResource
  include AssumedRole

  def index
    # Rails 5 requires parameters to be explicitly permitted before converting 
    # to Hash.  See: https://stackoverflow.com/a/46029524
    allowed_params = %i[account kind limit offset search]
    options = params.permit(*allowed_params)
      .slice(*allowed_params).to_h.symbolize_keys

    if params[:owner]
      ownerid = Role.make_full_id(params[:owner], account)
      options[:owner] = Role[ownerid] or raise Exceptions::RecordNotFound, ownerid
    end

    # The v5 API currently sends +acting_as+ when listing resources
    # for a role other than the current user.
    query_role = params[:role].presence || params[:acting_as].presence
    begin
      scope = Resource.visible_to(assumed_role(query_role)).search options
    rescue ApplicationController::Forbidden
      raise
    rescue ArgumentError => e
      raise ApplicationController::UnprocessableEntity, e.message
    end

    result =
      if params[:count] == 'true'
        { count: scope.count('*'.lit) }
      else
        scope.select(:resources.*).
          eager(:annotations).
          eager(:permissions).
          eager(:secrets).
          eager(:policy_versions).
          all
      end

    render json: result
  end

  def show
    render json: resource
  end

  def permitted_roles
    privilege = params[:privilege] || params[:permission]
    raise ArgumentError, "privilege" unless privilege
    render json: Role.that_can(privilege, resource).map(&:id)
  end

  # Implements the use case "check permission on some resource",
  # either for the role specified by the query string, or for the
  # +current_user+.
  def check_permission
    privilege = params[:privilege]
    raise ArgumentError, "privilege" unless privilege

    begin
      result = assumed_role.allowed_to?(privilege, resource)
    rescue
      result = false
      resource_id = "#{params[:account]}:#{params[:kind]}:#{params[:identifier]}"
      role_id = params[:role]

      Audit.logger.log(
        Audit::Event::Check.new(
          user: current_user,
          client_ip: request.ip,
          resource: resource_id,
          privilege: privilege,
          role: role_id,
          operation: "check",
          success: result
        )
      )
    end

    Audit.logger.log(
      Audit::Event::Check.new(
        user: current_user,
        client_ip: request.ip,
        resource: resource,
        privilege: privilege,
        role: assumed_role,
        operation: "check",
        success: result
      )
    )

    head(result ? :no_content : :not_found)
  end
end
