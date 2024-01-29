class V2SecretsController < V2RestController
  include AuthorizeResource
  include BodyParser

  def create
    branch = params[:branch]
    secret_name = params[:name]
    secret_type = params[:type]
    log_message = "Create Secret #{secret_type}:#{branch}/#{secret_name}"
    logger.debug(LogMessages::Endpoints::EndpointRequested.new(log_message))

    # Check permissions
    action = :update
    authorize(action, resource("policy", branch))

    # Create the secret type class
    secret_type_handler = SecretTypeFactory.new.create_secret_type(secret_type)

    secret_type_handler.input_validation(secret_name)

    resource_id = resource_id("variable","#{branch}/#{secret_name}")
    policy_id = resource_id("policy",branch)
    policy = Role[policy_id]
    raise Exceptions::RecordNotFound, policy_id unless policy
    secret_type_handler.create_variable(resource_id, policy)

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
end