class StaticSecretsController < V2RestController
  include AuthorizeResource
  include BodyParser
  include ParamsValidator

  SECRET_TYPE = "static"

  def show
    # Return a static secret name and value

    branch = request.params[:branch]
    secret_name = request.params[:name]

    get_secret_enpoint_log_message = "Get Static Secret #{branch}/#{secret_name}"
    logger.debug(LogMessages::Endpoints::EndpointRequested.new(get_secret_enpoint_log_message))

    secret_type_handler = Secrets::SecretTypes::StaticSecretType.new
    secret_type_handler.input_validation(request.params)

    variable = get_resource("variable", "#{branch}/#{secret_name}")
    check_read_permissions(secret_type_handler, variable)

    response = secret_type_handler.as_json(branch, secret_name, variable)
    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new(get_secret_enpoint_log_message))
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
