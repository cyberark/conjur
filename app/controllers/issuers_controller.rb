# frozen_string_literal: true

class IssuersController < RestController
  include AuthorizeResource
  include PolicyTemplates::TemplatesRenderer
  include BodyParser
  include FindIssuerResource
  include RequestContext

  before_action :current_user
  before_action :find_or_create_root_policy

  rescue_from Sequel::UniqueConstraintViolation, with: :concurrent_load

  ISSUER_NOT_FOUND = "Issuer not found"
  SENSITIVE_DATA_MASK = "*****"

  def initialize(
    *args,
    policy: CommandHandler::Policy.new,
    **kwargs
  )
    super(*args, **kwargs)

    @policy = policy
  end

  def update
    logger.debug do
      LogMessages::Endpoints::EndpointRequested.new(
        "PATCH issuers/#{params[:account]}/update/#{params[:identifier]}"
      )
    end

    action = :update
    authorize(action, resource)

    issuer = Issuer.find(issuer_id: params[:identifier])
    if issuer.nil?
      raise Exceptions::RecordNotFound.new(
        params[:identifier],
        message: ISSUER_NOT_FOUND
      )
    end

    issuer_type = Issuers::IssuerTypes::IssuerTypeFactory.new.create_issuer_type(issuer.issuer_type)
    issuer_type.validate_update(body_params)

    update_issuer_ttl(params, issuer)
    update_issuer_data(params, issuer)

    issuer.save

    issuer_audit_success(issuer.account, issuer.issuer_id, "update")

    json_response = issuer_type.mask_sensitive_data_in_response(issuer.as_json)
    render(json: json_response, status: :ok)
  rescue => e
    issuer_audit_failure(
      params[:account],
      params[:identifier],
      "update",
      e.message
    )
    raise e
  end

  def create
    logger.debug do
      LogMessages::Endpoints::EndpointRequested.new(
        "POST issuers/#{params[:account]}"
      )
    end

    # If the base policy for issuers doesn't yet exist, create it as a
    # UX convenience. It can still be pre-created with specific ownership
    # and permissions. However, if the user is about to create an issuer and
    # it fails because the base policy doesn't exist, the next action will
    # be to create the base policy. So we save a try/repeat step by creating
    # it here.
    create_issuer_base_policy(params[:account]) unless resource_exists?

    action = :create
    authorize(action, resource)

    issuer_type = Issuers::IssuerTypes::IssuerTypeFactory.new.create_issuer_type(params[:type])
    issuer_type.validate(body_params)

    issuer_resource = Issuer.find(issuer_id: params[:id])
    unless issuer_resource.nil?
      raise Exceptions::RecordExists.new("issuer", params[:id])
    end

    issuer = Issuer.new(
      issuer_id: params[:id],
      account: params[:account],
      issuer_type: params[:type],
      max_ttl: params[:max_ttl],
      data: params[:data].to_json,
      modified_at: Time.now,
      policy_id: "#{params[:account]}:policy:conjur/issuers/#{params[:id]}"
    )

    if issuer.issuer_variables_exist?
      raise ApplicationController::InternalServerError,
            "Found variables associated with the issuer id"
    end

    create_issuer_policy({ "id" => params[:id] })

    issuer.save
    issuer_audit_success(issuer.account, issuer.issuer_id, "add")

    json_response = issuer_type.mask_sensitive_data_in_response(issuer.as_json)
    render(json: json_response, status: :created)

    logger.debug do
      LogMessages::Endpoints::EndpointFinishedSuccessfully.new(
        "POST issuers/#{params[:account]}"
      )
    end
  rescue Exceptions::RecordNotFound => e
    logger.warn(LogMessages::Issuers::IssuerEndpointForbidden.new("create"))
    issuer_audit_failure(params[:account], params[:id], "add", e.message)
    raise Exceptions::Forbidden, "issuers"
  rescue ApplicationController::BadRequestWithBody, ApplicationController::UnprocessableEntity => e
    logger.warn(
      "Input validation error for issuer [#{params[:id]}]: #{e.message}"
    )
    issuer_audit_failure(params[:account], params[:id], "add", e.message)
    raise
  rescue Exceptions::RecordExists => e
    logger.warn("The issuer [#{params[:id]}] already exists")
    issuer_audit_failure(params[:account], params[:id], "add", e.message)
    raise
  rescue => e
    issuer_audit_failure(params[:account], params[:id], "add", e.message)
    logger.error(LogMessages::Conjur::GeneralError.new(e.message))
    raise
  end

  def delete
    logger.debug do
      LogMessages::Endpoints::EndpointRequested.new(
        "DELETE issuers/#{params[:account]}/#{params[:identifier]}"
      )
    end

    action = :update
    authorize(action, resource)

    issuer = get_issuer_from_db(params[:account], params[:identifier])
    if issuer
      # Deleting the issuer policy causes a cascade delete of the issuers object
      # as well
      delete_issuer_policy({ "id" => params[:identifier] })

      # Unless requested otherwise, we need to keep the issuer related variables
      unless params[:keep_secrets] == "true"
        begin
          deleted_variables = issuer.delete_issuer_variables

          issuer_variables_audit_delete(
            issuer.account,
            issuer.issuer_id,
            deleted_variables
          )
        rescue => e
          error_message = \
            "Failed deleting Issuer #{params[:identifier]} variables. " \
            "#{e.message}"

          raise ApplicationController::InternalServerError, error_message
        end
      end

      issuer_audit_success(issuer.account, issuer.issuer_id, "remove")
      head(:no_content)
    else
      raise Exceptions::RecordNotFound.new(
        params[:identifier],
        message: ISSUER_NOT_FOUND
      )
    end

    logger.debug do
      LogMessages::Endpoints::EndpointFinishedSuccessfully.new(
        "DELETE issuers/#{params[:account]}/#{params[:identifier]}"
      )
    end
  rescue Exceptions::RecordNotFound => e
    logger.warn(LogMessages::Issuers::IssuerPolicyNotFound.new(resource_id))
    issuer_audit_failure(
      params[:account],
      params[:identifier],
      "remove",
      e.message
    )

    raise Exceptions::RecordNotFound.new(
      params[:identifier],
      message: ISSUER_NOT_FOUND
    )
  rescue => e
    issuer_audit_failure(
      params[:account],
      params[:identifier],
      "remove",
      e.message
    )

    logger.error(LogMessages::Conjur::GeneralError.new(e.message))

    raise
  end

  def get
    logger.debug do
      LogMessages::Endpoints::EndpointRequested.new(
        "GET issuers/#{params[:account]}/#{params[:identifier]}"
      )
    end

    action = :read
    authorize(action, resource)

    issuer = get_issuer_from_db(params[:account], params[:identifier])
    if issuer
      issuer_type = Issuers::IssuerTypes::IssuerTypeFactory.new.create_issuer_type(issuer.issuer_type)

      if minimum_request?(params)
        operation, result =  issuer_type.handle_minimum(issuer)
      else
        operation = "fetch"
        result = issuer.as_json
      end
      issuer_audit_success(issuer.account, issuer.issuer_id, operation)

      json_response = issuer_type.mask_sensitive_data_in_response(result)
      render(json: json_response, status: :ok)
    else
      # If this exception is reached, then the issuer policy record exists, but
      # the issuer table record does not.
      raise Exceptions::RecordNotFound.new(
        params[:identifier],
        message: ISSUER_NOT_FOUND
      )
    end

    logger.debug do
      LogMessages::Endpoints::EndpointFinishedSuccessfully.new(
        "GET issuers/#{params[:account]}/#{params[:identifier]}"
      )
    end
  rescue Exceptions::RecordNotFound
    issuer_audit_failure(
      params[:account],
      params[:identifier],
      "fetch",
      ISSUER_NOT_FOUND
    )

    logger.warn(LogMessages::Issuers::IssuerPolicyNotFound.new(resource_id))
    logger.info(
      LogMessages::Endpoints::EndpointFinishedSuccessfully.new(
        "GET issuers/#{params[:account]}/#{params[:identifier]}"
      )
    )

    raise Exceptions::RecordNotFound.new(
      params[:identifier],
      message: ISSUER_NOT_FOUND
    )
  rescue => e
    issuer_audit_failure(
      params[:account],
      params[:identifier],
      "fetch",
      e.message
    )

    logger.error(LogMessages::Conjur::GeneralError.new(e.message))

    raise
  end

  def list
    logger.debug do
      LogMessages::Endpoints::EndpointRequested.new(
        "GET issuers/#{params[:account]}"
      )
    end

    # If I can update the issuer policy, it means I am allowed to view it as well
    action = :update
    authorize(action, resource)
    issuers = list_issuers_from_db(params[:account])

    results = []
    issuers.each do |item|
      issuer_type = Issuers::IssuerTypes::IssuerTypeFactory.new.create_issuer_type(item.issuer_type)
      results.push(issuer_type.mask_sensitive_data_in_response(item.as_json))
    end
    results = params[:sort] ? sort_by_key(results, params[:sort]) : results

    issuer_audit_success(params[:account], "*", "list")

    render(json: { issuers: results }, status: :ok)

    logger.debug do
      LogMessages::Endpoints::EndpointFinishedSuccessfully.new(
        "GET issuers/#{params[:account]}"
      )
    end
  rescue Exceptions::RecordNotFound => e
    logger.warn(LogMessages::Issuers::IssuerEndpointForbidden.new("list"))
    issuer_audit_failure(params[:account], "*", "list", e.message)
    raise Exceptions::Forbidden, "issuers"
  rescue => e
    issuer_audit_failure(params[:account], "*", "list", e.message)
    logger.error(LogMessages::Conjur::GeneralError.new(e.message))
    raise e
  end

  private

  def minimum_request?(params)
    return false unless params.key?(:projection)

    # If there is use permissions I can see the minimum info
    return true if params[:projection] == "minimal"

    raise ApplicationController::UnprocessableEntity,
          "Value provided for projection query param is invalid"
  end
end

# Function to sort array of hashes by a specified key in asc order
def sort_by_key(array, key)
  result = array

  unless array.empty?
    # check the key is a valid field
    unless array[0].key?(key.to_sym)
      raise ApplicationController::BadRequestWithBody,
            "the sort key #{key} is not a valid field of the issuer object"
    end
    result = array.sort_by { |hash| hash[key.to_sym] }
  end

  result
end

def create_issuer_base_policy(account)
  # This command handles creating policy load audit records
  @policy.call(
    target_policy_id: "#{account}:policy:root",
    context: context,
    policy: renderer(PolicyTemplates::Issuers::IssuerBase.new),
    loader: Loader::CreatePolicy,
    request_type: 'POST'
  ).bind!
end

def create_issuer_policy(policy_fields)
  # This command handles creating policy load audit records
  @policy.call(
    target_policy_id: resource.resource_id,
    context: context,
    policy: renderer(PolicyTemplates::Issuers::CreateIssuer.new, policy_fields),
    loader: Loader::CreatePolicy,
    request_type: 'POST'
  ).bind!
end

def delete_issuer_policy(policy_fields)
  # This command handles creating policy load audit records
  @policy.call(
    target_policy_id: resource.resource_id,
    context: context,
    policy: renderer(PolicyTemplates::Issuers::DeleteIssuer.new, policy_fields),
    loader: Loader::ModifyPolicy,
    request_type: 'PATCH'
  ).bind!
end

def get_issuer_from_db(account, issuer_id)
  Issuer.where(account: account, issuer_id: issuer_id).first
end

def list_issuers_from_db(account)
  Issuer.where(account: account).all
end

def issuer_audit_success(account, issuer_id, operation)
  subject = { account: account, issuer: issuer_id }
  Audit.logger.log(
    Audit::Event::Issuer.new(
      user_id: current_user.role_id,
      client_ip: request.ip,
      subject: subject,
      message_id: "issuer",
      success: true,
      operation: operation
    )
  )
end

def issuer_audit_failure(account, issuer_id, operation, error_message)
  subject = { account: account, issuer: issuer_id }
  Audit.logger.log(
    Audit::Event::Issuer.new(
      user_id: current_user.role_id,
      client_ip: request.ip,
      subject: subject,
      message_id: "issuer",
      success: false,
      operation: operation,
      error_message: error_message
    )
  )
end

def issuer_variables_audit_delete(account, issuer_id, deleted_variables)
  deleted_variables.each do |variable_id|
    subject = { account: account, issuer: issuer_id, resource_id: variable_id }
    Audit.logger.log(
      Audit::Event::IssuerVariable.new(
        user_id: current_user.role_id,
        client_ip: request.ip,
        subject: subject,
        message_id: "variable",
        success: true,
        operation: "remove"
      )
    )
  end
end

# This function updates the issuer data but
# requires the user to call issuer.save
# This is to save DB calls
def update_issuer_data(params, issuer)
  return unless params.key?(:data)

  issuer.update(data: params[:data].to_json, modified_at: Time.now)
end

# This function updates the issuer max_ttl but
# requires the user to call issuer.save
# This is to save DB calls
def update_issuer_ttl(params, issuer)
  return unless params.key?(:max_ttl)

  if issuer.max_ttl > params[:max_ttl]
    raise ApplicationController::BadRequestWithBody,
          "The new max_ttl must be equal or higher than the current max_ttl"
  end

  issuer.update(max_ttl: params[:max_ttl], modified_at: Time.now)
end
