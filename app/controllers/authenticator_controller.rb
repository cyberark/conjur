# frozen_string_literal: true

class AuthenticatorController < V2RestController
  include BasicAuthenticator
  include AuthorizeResource

  def initialize(
    *args,
    res_repo: ::Resource,
    **kwargs
  )
    super(*args, **kwargs)

    @res_repo = res_repo.visible_to(current_user)
  end

  def list_authenticators
    relevant_params = parse_params(%i[limit offset type account])

    repository = DB::Repository::AuthenticatorRepository.new(
      resource_repository: @res_repo.search(
        **relevant_params.slice(:offset, :limit)
      )
    )

    total_count = repository.count_all(
      account: relevant_params[:account],
      type: relevant_params[:type],
      repo: @res_repo
    )

    response = repository.find_all(
      account: relevant_params[:account],
      type: relevant_params[:type]
    ).bind do |res|
      auths = res.map(&:to_h)
      ::SuccessResponse.new({ authenticators: auths, count: total_count })
    end

    response_audit('list', 'authenticators', response)
    return render(json: response.result) if response.success?

    handle_failure_response(response)
  rescue => e
    failure_audit('list', 'authenticators', e.message)
    log_backtrace(e)
    raise
  end

  def create_authenticator
    relevant_params = parse_params(%i[account])
    valid_body = nil
    response = request_body.bind do |body|
      valid_body = body
      AuthenticatorsV2::AuthenticatorTypeFactory.new.create_authenticator_from_json(req, relevant_params[:account]).bind do |auth| 
        validate_create_permisisons(auth).bind do |permitted_auth|
          verify_owner(permitted_auth).bind do |auth_with_owner|
            DB::Repository::AuthenticatorRepository.new.create(authenticator: auth_with_owner).bind do |created_auth|
              ::SuccessResponse.new(created_auth.to_h)
            end
          end 
        end
      end
    end

    type = valid_body&.dig(:type) || 'authenticator'
    name = valid_body&.dig(:name) || ''
    response_audit('create', type, response, resource_id: name)

    return render(json: response.result, status: :created) if response.success?

    handle_failure_response(response)
  rescue => e
    failure_audit('create', 'authenticator', e.message)
    log_backtrace(e)
    raise e
  end

  def find_authenticator
    relevant_params = parse_params(%i[type account service_id])
    response = retrieve_authenticator(
      relevant_params,
      resource_repo: @res_repo
    )

    response_audit('get', relevant_params[:type], response,  resource_id: relevant_params[:service_id])
    return render(json: response.result.to_h) if response.success?

    handle_failure_response(response)
  rescue => e
    failure_audit('get', relevant_params[:type], e.message,  resource_id: relevant_params[:service_id])
    log_backtrace(e)
    raise
  end

  def authenticator_enablement
    relevant_params = parse_params(%i[type account service_id])
    response = validate_request_body.bind do |enablement| 
      update_config(relevant_params, enablement).bind do
        retrieve_authenticator(relevant_params)
      end
    end

    response_audit('enable', relevant_params[:type], response, resource_id: relevant_params[:service_id])
    return render(json: response.result.to_h) if response.success?
  
    handle_failure_response(response)
  rescue => e
    failure_audit('enable', relevant_params[:type], e.message, resource_id: relevant_params[:service_id])
    log_backtrace(e)
    raise
  end

  def delete_authenticator
    relevant_params = parse_params(%i[type account service_id])

    repository = DB::Repository::AuthenticatorRepository.new(
      resource_repository: @res_repo
    )

    response = repository.find(
      type: relevant_params[:type],
      account: relevant_params[:account],
      service_id: relevant_params[:service_id]
    ).bind do |auth|
      policy_id = auth.resource_id.gsub('webservice', 'policy')

      unless current_user.allowed_to?('delete', ::Resource[policy_id])
        next ::FailureResponse.new(
          "Unauthorized",
          status: :forbidden,
          exception: Exceptions::Forbidden
        )
      end
      policy = repository.delete(policy_id: policy_id)
      ::SuccessResponse.new(policy, status: :no_content)
    end

    response_audit('delete', relevant_params[:type], response, resource_id: relevant_params[:service_id])
    return head(response.status) if response.success?

    handle_failure_response(response)
  rescue => e
    failure_audit('delete', relevant_params[:type], e.message, resource_id: relevant_params[:service_id])
    log_backtrace(e)
    raise
  end

  private

  def retrieve_authenticator(relevant_params, resource_repo: ::Resource)
    DB::Repository::AuthenticatorRepository.new(
      resource_repository: resource_repo
    ).find(
      account: relevant_params[:account],
      type: relevant_params[:type],
      service_id: relevant_params[:service_id]
    )
  end

  def handle_failure_response(response)
    render(
      json: { 
        code: Rack::Utils.status_code(response.status).to_s, 
        message: response.message 
      }, 
      status: response.status
    )
  end

  def parse_params(allowed)
    params = allowed_params(allowed)

    # We refer to authenticators by the full authn-<type> format in code rather than the shortened form
    params[:type] = "authn-#{params[:type]}" if params[:type]

    params
  end

  def allowed_params(allowed)
    params.permit(*allowed)
      .slice(*allowed).to_h.symbolize_keys
  end

  def validate_create_permisisons(auth)
    auth_branch = "#{auth.account}:policy:#{auth.branch}"
    resource = Resource[auth_branch]
    
    unless resource&.visible_to?(current_user) 
      return ::FailureResponse.new(
        "#{auth.owner} not found in account #{auth.account}",
        exception: Exceptions::RecordNotFound.new(auth.owner),
        status: :not_found
      )
    end
    authorize(:create, resource)
    ::SuccessResponse.new(auth) 
  end

  def verify_owner(auth)
    return ensure_owner_exists(auth) unless auth.owner.nil?

    ::SuccessResponse.new(auth)
  end

  def ensure_owner_exists(auth)
    owner = Resource[auth.owner]
    return ::SuccessResponse.new(auth) if owner&.visible_to?(current_user) 

    ::FailureResponse.new(
      "#{auth.owner} not found in account #{auth.account}",
      exception: Exceptions::RecordNotFound.new(auth.owner),
      status: :not_found
    )
  end

  def validate_request_body
    request_body.bind do |body|
      if !required_key?(body)
        missing_param(:enabled)
      elsif extra_keys?(body.keys, [:enabled])
        extra_keys(body.keys, [:enabled])
      elsif !bool?(body[:enabled])
        mismatch_type("enabled", "boolean")
      else
        ::SuccessResponse.new(body[:enabled])
      end
    end
  end

  def required_key?(body)
    body.key?(:enabled)
  end

  def extra_keys?(keys, required)
    collect_extra_keys(keys, required).count.positive?
  end

  def bool?(field)
    field.in?([true, false])
  end

  def collect_extra_keys(keys, required)
    keys.tap do |k| 
      required.each { |r| k.delete(r) }
    end
  end

  def request_body
    return missing_request_body unless req.present?
    
    ::SuccessResponse.new(
      JSON.parse(
        req,       
        {
          symbolize_names: true,
          create_additions: false
        }
      )
    )
  rescue
    ::FailureResponse.new(
      "Request JSON is malformed",
      status: :bad_request,
      exception: BadRequestWithBody
    )
  end

  def req 
    @req ||= request.body.read
  end
  
  def update_config(relevant_params, body) 
    config_input = update_config_input(relevant_params, body)

    begin
      ::SuccessResponse.new(
        Authentication::UpdateAuthenticatorConfig.new.(
          update_config_input: config_input
        )
      )
    rescue Errors::Authentication::Security::WebserviceNotFound => e
      resource_id = "#{relevant_params[:type]}/#{relevant_params[:service_id]}"
      ::FailureResponse.new(
        "Authenticator: #{resource_id} not found in account '#{relevant_params[:account]}'",
        status: :not_found,
        exception: e
      )
    rescue Errors::Authentication::Security::RoleNotAuthorizedOnResource => e
      ::FailureResponse.new(
        e.message,
        status: :forbidden,
        exception: e
      )
    end
  end

  def update_config_input(relevant_params, enabled_status)
    @update_config_input ||= Authentication::UpdateAuthenticatorConfigInput.new(
      account: relevant_params[:account],
      authenticator_name: relevant_params[:type],
      service_id: relevant_params[:service_id],
      username: ::Role.username_from_roleid(current_user.role_id),
      enabled: enabled_status.to_s,
      client_ip: request.ip
    )
  end

  # Request body failures

  def missing_param(param)
    ::FailureResponse.new(
      "Missing required parameter: #{param}",
      status: :unprocessable_entity,
      exception: BadRequestWithBody
    )
  end

  def missing_request_body
    ::FailureResponse.new(
      "Request body is empty",
      status: :bad_request,
      exception: BadRequestWithBody
    )
  end

  def extra_keys(keys, required)
    extra_keys = collect_extra_keys(keys, required).compact.join(', ')
    
    ::FailureResponse.new(
      "The following parameters were not expected: '#{extra_keys}'",
      status: :unprocessable_entity,
      exception: BadRequestWithBody
    )
  end

  def mismatch_type(param, type)
    ::FailureResponse.new(
      "The #{param} parameter must be of type=#{type}",
      status: :unprocessable_entity,
      exception: BadRequestWithBody
    )
  end

  def failure_audit(operation, resource_type, error, resource_id: '')
    audit_event(
      operation,
      resource_type,
      resource_id,
      req.present? ? req : nil,
      error
    )
  end

  def response_audit(operation, resource_type, response, resource_id: '')
    audit_event(
      operation,
      resource_type,
      resource_id,
      req.present? ? req : nil,
      response.success? ? nil : response.message
    )
  end
end
