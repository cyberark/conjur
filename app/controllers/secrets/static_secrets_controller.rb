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
    static_secret.input_validation(params)

    # Check permissions
    create_permissions = static_secret.get_create_permissions(params)
    create_permissions.each do |action_policy, action|
      authorize(action, action_policy)
    end

    # Create variable resource
    created_secret = static_secret.create_secret(branch, secret_name, params)

    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new(log_message))
    render(json: created_secret, status: :created)
    # audit_succsess
  rescue => e
    #audit_failure(e, :remove)
    raise e
  end

  def show
    # Return a static secret name and value
    branch = request.params[:branch]
    secret_name = request.params[:name]

    get_secret_log_message = "Get Static Secret #{branch}/#{secret_name}"
    logger.debug(LogMessages::Endpoints::EndpointRequested.new(get_secret_log_message))

    secret_type_handler = Secrets::SecretTypes::StaticSecretType.new
    secret_type_handler.input_validation(request.params)

    variable = get_resource("variable", "#{branch}/#{secret_name}")
    check_read_permissions(secret_type_handler, variable)

    response = secret_type_handler.as_json(branch, secret_name, variable)
    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new(get_secret_log_message))
    render(json: response.to_json, status: :ok)
  end

  private
  def check_read_permissions(secret_type_handler, variable)
    read_permission = secret_type_handler.get_read_permissions(variable)
    read_permission.each do |resource, action|
      authorize(action, resource)
    end
  end
end