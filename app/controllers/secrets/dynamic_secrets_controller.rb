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
end