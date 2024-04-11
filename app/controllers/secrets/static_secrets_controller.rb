class StaticSecretsController < V2RestController
  include AuthorizeResource
  include BodyParser
  include ParamsValidator

  def create
    branch = params[:branch]
    secret_name = params[:name]
    log_message = "Create Static Secret #{branch}/#{secret_name}"
    logger.debug(LogMessages::Endpoints::EndpointRequested.new(log_message))

    # Create the secret type class
    static_secret = Secrets::SecretTypes::StaticSecretType.new

    #Run input validation specific to secret type
    static_secret.create_input_validation(params)

    # Check permissions
    create_permissions = static_secret.get_create_permissions(params)
    create_permissions.each do |action_policy, action|
      authorize(action, action_policy)
    end

    # Create variable resource
    created_secret = static_secret.create_secret(branch, secret_name, params)

    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new(log_message))
    render(json: created_secret, status: :created)
    send_success_audit('secret',"create", branch, secret_name, request.path, body_payload)
  rescue => e
    send_failure_audit('secret', "create", params[:branch], params[:name], request.path, body_payload, e.message)
    raise e
  end

  def show
    # As the branch is part of the path we loose the / prefix
    branch = request.params[:branch]
    secret_name = request.params[:name]

    get_secret_log_message = "Get Static Secret #{branch}/#{secret_name}"
    logger.debug(LogMessages::Endpoints::EndpointRequested.new(get_secret_log_message))

    secret_type_handler = Secrets::SecretTypes::StaticSecretType.new
    variable = secret_type_handler.get_input_validation(request.params)

    check_read_permissions(secret_type_handler, variable)

    response = secret_type_handler.as_json(branch, secret_name, variable)
    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new(get_secret_log_message))
    render(json: response, status: :ok)
    send_success_audit('secret',"get", branch, secret_name, request.path, nil)
  rescue => e
    send_failure_audit( 'secret', "get", request.params[:branch], request.params[:name], request.path, nil, e.message)
    raise e
  end

  def replace
    # As the branch is part of the path we loose the / prefix
    branch = params[:branch]
    secret_name = params[:name]

    log_message = "Replace Static Secret #{branch}/#{secret_name}"
    logger.debug(LogMessages::Endpoints::EndpointRequested.new(log_message))

    static_secret = Secrets::SecretTypes::StaticSecretType.new

    #Run input validation specific to secret type
    secret = static_secret.update_input_validation(params, body_params)

    # Check permissions
    create_permissions = static_secret.get_update_permissions(params, secret)
    create_permissions.each do |action_policy, action|
      authorize(action, action_policy)
    end

    # Update secret
    updated_secret = static_secret.replace_secret(branch, secret_name, secret, params)

    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new(log_message))
    render(json: updated_secret, status: :ok)
    send_success_audit('secret',"change", branch, secret_name, request.path, body_payload)
  rescue => e
    send_failure_audit( 'secret', "change", request.params[:branch], request.params[:name], request.path, body_payload, e.message)
    raise e
  end

  private

  def check_read_permissions(secret_type_handler, variable)
    read_permission = secret_type_handler.get_read_permissions(variable)
    read_permission.each do |resource, action|
      authorize(action, resource)
    end
  end
end