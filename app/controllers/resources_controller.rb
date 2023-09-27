# frozen_string_literal: true

class ResourcesController < RestController
  include FindResource
  include AssumedRole

  def index
    # Rails 5 requires parameters to be explicitly permitted before converting 
    # to Hash.  See: https://stackoverflow.com/a/46029524
    allowed_params = %i[account kind limit offset search exclude]
    options = params.permit(*allowed_params)
      .slice(*allowed_params).to_h.symbolize_keys

    # If a maximum limit is configured, we need to verify that the requested
    # limit does not exceed the maximum.
    # The maximum limit should not be apply if this is a count request.
    if conjur_config.api_resource_list_limit_max.positive? && !params[:count]
      # If no limit is given, default the limit to the configured maximum
      options[:limit] = conjur_config.api_resource_list_limit_max.to_s unless options[:limit]

      unless options[:limit].to_i <= conjur_config.api_resource_list_limit_max
        error_message = "'Limit' parameter must not exceed #{conjur_config.api_resource_list_limit_max}"
        audit_list_failure(options, error_message)
        raise ApplicationController::UnprocessableEntity, error_message

      end
    end

    if params[:owner]
      ownerid = Role.make_full_id(params[:owner], account)
      (options[:owner] = Role[ownerid]) || raise(Exceptions::RecordNotFound, ownerid)
    end

    # The v5 API currently sends +acting_as+ when listing resources
    # for a role other than the current user.
    query_role = params[:role].presence || params[:acting_as].presence
    begin
      scope = Resource.visible_to(assumed_role(query_role)).search(**options)
    rescue ApplicationController::Forbidden
      audit_list_failure(options, "The authenticated user lacks the necessary privilege")
      raise
    rescue ArgumentError => e
      audit_list_failure(options, e.message)
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
    audit_list_success(options)
    render(json: result)
  end

  def show
    show_audit = true
    #If the request came from UI ip and have the header we won't send audit
    if is_ip_trusted && request.headers['X-Request-Source']=="UI"
      show_audit = false
    end
    show_resource(show_audit)
  end

  def permitted_roles
    privilege = params[:privilege] || params[:permission]
    raise ArgumentError, "privilege" unless privilege

    render(json: Role.that_can(privilege, resource).map(&:id))
  end

  # Implements the use case "check permission on some resource",
  # either for the role specified by the query string, or for the
  # +current_user+.
  def check_permission
    privilege = params[:privilege]
    raise ArgumentError, "privilege" unless privilege

    begin
      result = assumed_role.allowed_to?(privilege, resource)

      audit_success(privilege, result)
    rescue => e
      audit_failure(privilege, e)

      raise
    end

    head(result ? :no_content : :not_found)
  end

  def audit_success(privilege, result)
    Audit.logger.log(
      Audit::Event::Check.new(
        user: current_user,
        client_ip: request.ip,
        resource_id: resource.id,
        privilege: privilege,
        role_id: assumed_role.id,
        operation: "check",
        success: result
      )
    )
  end

  def audit_failure(privilege, err)
    role_id = params[:role]

    Audit.logger.log(
      Audit::Event::Check.new(
        user: current_user,
        client_ip: request.ip,
        resource_id: resource_id,
        privilege: privilege,
        role_id: role_id,
        operation: "check",
        success: false,
        error_message: err.message
      )
    )
  end

  def conjur_config
    Rails.application.config.conjur_config
  end

  private

  def audit_list_success(options)
    additional_params = %i[count acting_as role]
    additional_options = params.permit(*additional_params)
      .slice(*additional_params).to_h.symbolize_keys
    Audit.logger.log(
      Audit::Event::List.new(
        user_id: current_user.role_id,
        client_ip: request.ip,
        subject: options.clone.merge(additional_options),
        success: true
      )
    )
  end

  def audit_list_failure(options, error_message)
    additional_params = %i[count acting_as role]
    additional_options = params.permit(*additional_params)
      .slice(*additional_params).to_h.symbolize_keys
    Audit.logger.log(
      Audit::Event::List.new(
        user_id: current_user.role_id,
        client_ip: request.ip,
        subject: options.clone.merge(additional_options),
        success: false,
        error_message: error_message
      )
    )
  end

  def audit_show_success
    subject = { resource: resource_id }
    Audit.logger.log(
      Audit::Event::Show.new(
        user_id: current_user.role_id,
        client_ip: request.ip,
        subject: subject,
        message_id: "resource",
        success: true
      )
    )
  end

  def audit_show_failure(error_message)
    subject = { resource: resource_id }
    Audit.logger.log(
      Audit::Event::Show.new(
        user_id: current_user.role_id,
        client_ip: request.ip,
        subject: subject,
        message_id: "resource",
        success: false,
        error_message: error_message
      )
    )
  end

  def show_resource(show_audit)
    result = resource
    if show_audit
      audit_show_success
    end
    render(json: result)
  rescue => e
    if show_audit
      audit_show_failure(e.message)
    end
    raise e
  end

  def is_ip_trusted
    request_ip = request.headers['HTTP_X_FORWARDED_FOR'].to_s.split(",")
    request_ip.any?{|x| Rack::Request.ip_filter.call(x.strip)}
  end

end
