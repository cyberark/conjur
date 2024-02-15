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

    # Create the secret type class
    secret_type_handler = SecretTypeFactory.new.create_secret_type(secret_type)
    # check policy exists
    policy_id = resource_id("policy",branch)
    policy = Resource[policy_id]
    raise Exceptions::RecordNotFound, policy_id unless policy

    #Run input validation specific to secret type
    secret_type_handler.input_validation(params)

    # Check permissions
    create_permissions = secret_type_handler.get_create_permissions(policy, params)
    create_permissions.each do |action_policy, action|
      authorize(action, action_policy)
    end

    # Create variable resource
    resource_id = resource_id("variable","#{branch}/#{secret_name}")
    created_secret = secret_type_handler.create_secret(policy, resource_id, params, JSON.parse(request.body.read))

    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new(log_message))
    render(json: created_secret, status: :created)
    #audit_succsess
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