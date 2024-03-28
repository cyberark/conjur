class DynamicSecretsController < V2RestController
  include AuthorizeResource
  include BodyParser
  include ParamsValidator

  def create
    branch = params[:branch]
    secret_name = params[:name]
    log_message = "Create Dynamic Secret #{branch}/#{secret_name}"
    logger.debug(LogMessages::Endpoints::EndpointRequested.new(log_message))

    # Create the dynamic type class
    dynamic_secret = Secrets::SecretTypes::DynamicSecretTypeFactory.new.create_dynamic_secret_type(params[:method])

    #Run input validation specific to secret type
    dynamic_secret.create_input_validation(params)

    # Check permissions
    create_permissions = dynamic_secret.get_create_permissions(params)
    create_permissions.each do |action_policy, action|
      authorize(action, action_policy)
    end

    # Create variable resource
    created_secret = dynamic_secret.create_secret(branch, secret_name, params)

    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new(log_message))
    render(json: created_secret, status: :created)
    #audit_succsess
  rescue => e
    #audit_failure(e, :remove)
    raise e
  end

  def replace
    branch = params[:branch]
    secret_name = params[:name]

    log_message = "Replace Dynamic Secret #{branch}/#{secret_name}"
    logger.debug(LogMessages::Endpoints::EndpointRequested.new(log_message))

    dynamic_secret = Secrets::SecretTypes::DynamicSecretTypeFactory.new.create_dynamic_secret_type(params[:method])

    #Run input validation specific to secret type
    secret = dynamic_secret.update_input_validation(params, body_params)

    # Check permissions
    create_permissions = dynamic_secret.get_update_permissions(params, secret)
    create_permissions.each do |action_policy, action|
      authorize(action, action_policy)
    end

    # Update secret
    updated_secret = dynamic_secret.replace_secret(branch, secret_name, secret, params)

    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new(log_message))
    render(json: updated_secret, status: :ok)
    #audit_succsess
  rescue => e
    #audit_failure(e, :remove)
    raise e
  end

  def show
    # As the branch is part of the path we loose the / prefix
    branch = request.params[:branch]
    secret_name = request.params[:name]

    get_secret_log_message = "Get Dynamic Secret #{branch}/#{secret_name}"
    logger.debug(LogMessages::Endpoints::EndpointRequested.new(get_secret_log_message))

    dynamic_secret = Secrets::SecretTypes::DynamicSecretType.new
    variable = dynamic_secret.get_input_validation(request.params)

    check_read_permissions(dynamic_secret, variable)

    response = dynamic_secret.as_json(branch, secret_name, variable)
    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new(get_secret_log_message))
    render(json: response, status: :ok)
  end

  private

  def check_read_permissions(secret_type_handler, variable)
    read_permission = secret_type_handler.get_read_permissions(variable)
    read_permission.each do |resource, action|
      authorize(action, resource)
    end
  end
end