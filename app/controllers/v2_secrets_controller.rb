class V2SecretsController < V2RestController
  include AuthorizeResource
  include BodyParser
  include ParamsValidator

  def create
    branch = params[:branch]
    secret_name = params[:name]
    secret_type = params[:type]
    log_message = "Create Secret #{secret_type}:#{branch}/#{secret_name}"
    logger.debug(LogMessages::Endpoints::EndpointRequested.new(log_message))

    # Basic input validation
    input_validation(params)

    # Check permissions
    action = :update
    authorize(action, resource("policy", branch))

    # Create the secret type class
    secret_type_handler = SecretTypeFactory.new.create_secret_type(secret_type)
    # Create the resources ids
    resource_id = resource_id("variable","#{branch}/#{secret_name}")
    policy_id = resource_id("policy",branch)
    policy = Role[policy_id]
    raise Exceptions::RecordNotFound, policy_id unless policy

    #Run input validation specific to secret type
    secret_type_handler.input_validation(params)

    # Create variable resource
    variable_resource = secret_type_handler.create_variable(resource_id, policy)

    # Set secret value
    secret_type_handler.set_value(variable_resource, params[:value])

    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new(log_message))
    render(json: {
      branch: branch,
      name: secret_name,
      type: secret_type
    }, status: :created)
  rescue => e
    #audit_failure(e, :remove)
    raise e
  end

  private

  def input_validation(params)
    data_fields = {
      name: String,
      branch: String,
      type: String
    }
    validate_required_data(params, data_fields.keys)
    validate_data(params, data_fields)

    # Validate the name of the secret is correct
    validate_name(params[:name])
  end
end