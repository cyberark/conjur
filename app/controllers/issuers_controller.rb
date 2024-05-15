# frozen_string_literal: true

require_relative '../controllers/wrappers/policy_wrapper'
require_relative '../controllers/wrappers/policy_audit'
require_relative '../controllers/wrappers/templates_renderer'
require_relative '../domain/issuers/issuer_types/issuer_type_factory'
class IssuersController < RestController
  include AccountValidator
  include AuthorizeResource
  include PolicyAudit
  include PolicyWrapper
  include PolicyTemplates::TemplatesRenderer
  include BodyParser
  include FindIssuerResource

  before_action :current_user
  before_action :find_or_create_root_policy

  rescue_from Sequel::UniqueConstraintViolation, with: :concurrent_load

  ISSUER_NOT_FOUND = "Issuer not found"
  SENSITIVE_DATA_MASK = "*****"

  def update
    logger.debug(LogMessages::Endpoints::EndpointRequested.new("PATCH issuers/#{params[:account]}/update/#{params[:identifier]}"))

    action = :update
    authorize(action, resource)

    issuer = Issuer.find(issuer_id: params[:identifier])
    raise Exceptions::RecordNotFound.new(params[:identifier], message: ISSUER_NOT_FOUND) if issuer.nil?
    
    issuer_type = IssuerTypeFactory.new.create_issuer_type(issuer.issuer_type)
    issuer_type.validate_update(body_params)

    update_issuer_ttl(params, issuer)
    update_issuer_data(params, issuer)
    
    issuer.save

    issuer_audit_success(issuer.account, issuer.issuer_id, "update")
    logger.info(LogMessages::Issuers::TelemetryIssuerLog.new("update", issuer.account, issuer.issuer_id, request.ip))
    json_response = mask_sensitive_data_in_response(issuer.as_json)
    render(json: json_response, status: :ok)
  rescue => e
    audit_failure(e, action)
    issuer_audit_failure(params[:account], params[:identifier], "update", e.message)
    raise e
  end

  def create
    logger.debug(LogMessages::Endpoints::EndpointRequested.new("POST issuers/#{params[:account]}"))
    action = :create
    authorize(action, resource)

    issuer_type = IssuerTypeFactory.new.create_issuer_type(params[:type])
    issuer_type.validate(body_params)

    issuerResource = Issuer.find(issuer_id: params[:id])
    if not issuerResource.nil?
      raise Exceptions::RecordExists.new("issuer", params[:id])
    end

    issuer = Issuer.new(issuer_id: params[:id], account: params[:account],
                        issuer_type: params[:type],
                        max_ttl: params[:max_ttl], data: params[:data].to_json,
                        modified_at: Time.now, 
                        policy_id: "#{params[:account]}:policy:conjur/issuers/#{params[:id]}")

    raise ApplicationController::InternalServerError, "Found variables associated with the issuer id" if issuer.issuer_variables_exist?

    create_issuer_policy({ "id" => params[:id] })
    issuer.save
    issuer_audit_success(issuer.account, issuer.issuer_id, "add")
    logger.info(LogMessages::Issuers::TelemetryIssuerLog.new("create", issuer.account, issuer.issuer_id, request.ip))
    json_response = mask_sensitive_data_in_response(issuer.as_json)
    render(json: json_response, status: :created)

    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("POST issuers/#{params[:account]}"))
  rescue Exceptions::RecordNotFound => e
    logger.warn(LogMessages::Issuers::IssuerEndpointForbidden.new("create"))
    audit_failure(e, action)
    issuer_audit_failure(params[:account], params[:id], "add", e.message)
    raise Exceptions::Forbidden, "issuers"
  rescue ApplicationController::BadRequestWithBody => e
    logger.warn("Input validation error for issuer [#{params[:id]}]: #{e.message}")
    audit_failure(e, action)
    issuer_audit_failure(params[:account], params[:id], "add", e.message)
    raise e
  rescue Exceptions::RecordExists => e
    logger.warn("The issuer [#{params[:id]}] already exists")
    audit_failure(e, action)
    issuer_audit_failure(params[:account], params[:id], "add", e.message)
    raise e
  rescue => e
    audit_failure(e, action)
    issuer_audit_failure(params[:account], params[:id], "add", e.message)
    logger.error(LogMessages::Conjur::GeneralError.new(e.message))
    head :internal_server_error
  end

  def delete
    logger.debug(LogMessages::Endpoints::EndpointRequested.new("DELETE issuers/#{params[:account]}/#{params[:identifier]}"))
    action = :update
    authorize(action, resource)

    issuer = get_issuer_from_db(params[:account], params[:identifier])
    if issuer
      # Deleting the issuer policy causes a cascade delete of the issuers object as well
      delete_issuer_policy({ "id" => params[:identifier] })
      # Unless requested otherwise, we need to keep the issuer related variables
      unless params[:keep_secrets] == "true"
        begin
          deleted_variables = issuer.delete_issuer_variables
          logger.info(LogMessages::Issuers::TelemetryIssuerLog.new("delete variables of", issuer.account, issuer.issuer_id, request.ip))
          issuer_variables_audit_delete(issuer.account, issuer.issuer_id, deleted_variables)
        rescue => e
          error_message = "Failed deleting Issuer #{params[:identifier]} variables. #{e.message}"
          raise ApplicationController::InternalServerError, error_message
        end
      end
      logger.info(LogMessages::Issuers::TelemetryIssuerLog.new("delete", issuer.account, issuer.issuer_id, request.ip))
      issuer_audit_success(issuer.account, issuer.issuer_id, "remove")
      head :no_content
    else
      raise Exceptions::RecordNotFound.new(params[:identifier], message: ISSUER_NOT_FOUND)
    end

    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("DELETE issuers/#{params[:account]}/#{params[:identifier]}"))
  rescue Exceptions::RecordNotFound => e
    logger.warn(LogMessages::Issuers::IssuerPolicyNotFound.new(resource_id))
    audit_failure(e, action)
    issuer_audit_failure(params[:account], params[:identifier], "remove", e.message)
    raise Exceptions::RecordNotFound.new(params[:identifier], message: ISSUER_NOT_FOUND)
  rescue => e
    audit_failure(e, action)
    issuer_audit_failure(params[:account], params[:identifier], "remove", e.message)
    logger.error(LogMessages::Conjur::GeneralError.new(e.message))
    raise e
  end

  def get
    logger.debug(LogMessages::Endpoints::EndpointRequested.new("GET issuers/#{params[:account]}/#{params[:identifier]}"))
    minimum_request = params.key?(:minimum)
    if minimum_request
      # If there is use permissions I can see the minimum info
      action = :use
    else
      # If I can update the issuer policy, it means I am allowed to view it as well
      action = :update
    end
    authorize(action, resource)

    issuer = get_issuer_from_db(params[:account], params[:identifier])
    if issuer
      if minimum_request
        operation = "fetch minimum"
        key_to_keep = "max_ttl"
        stripped_issuer = { key_to_keep => issuer[key_to_keep.to_sym] }
        result = stripped_issuer.as_json
      else
        operation = "fetch"
        result = issuer.as_json
      end
      issuer_audit_success(issuer.account, issuer.issuer_id, operation)
      logger.info(LogMessages::Issuers::TelemetryIssuerLog.new(operation, issuer.account, issuer.issuer_id, request.ip))
      json_response = mask_sensitive_data_in_response(result)
      render(json: json_response, status: :ok)
    else
      raise Exceptions::RecordNotFound.new(params[:identifier], message: ISSUER_NOT_FOUND)
    end

    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("GET issuers/#{params[:account]}/#{params[:identifier]}"))
  rescue Exceptions::RecordNotFound => e
    issuer_audit_failure(params[:account], params[:identifier], "fetch", ISSUER_NOT_FOUND)
    logger.warn(LogMessages::Issuers::IssuerPolicyNotFound.new(resource_id))
    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("GET issuers/#{params[:account]}/#{params[:identifier]}"))
    raise Exceptions::RecordNotFound.new(params[:identifier], message: ISSUER_NOT_FOUND)
  rescue => e
    issuer_audit_failure(params[:account], params[:identifier], "fetch", e.message)
    logger.error(LogMessages::Conjur::GeneralError.new(e.message))
    raise e
  end

  def list
    logger.debug(LogMessages::Endpoints::EndpointRequested.new("GET issuers/#{params[:account]}"))
    # If I can update the issuer policy, it means I am allowed to view it as well
    action = :update
    authorize(action, resource)

    issuers = list_issuers_from_db(params[:account])
    results = []
    issuers.each do |item|
      results.push(item.as_json_for_list)
    end
    results = params[:sort] ? sort_by_key(results, params[:sort]) : results
    issuer_audit_success(params[:account], "*", "list")
    logger.info(LogMessages::Issuers::TelemetryIssuerLog.new("list", params[:account], "*", request.ip))
    json_response = mask_sensitive_data_in_response(results)
    render(json: { issuers: json_response}, status: :ok)

    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("GET issuers/#{params[:account]}"))
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

  def mask_sensitive_data_in_response(response)
    if response.is_a?(Array)
      response.each do |item|
        mask_data_field(item)
      end
    else
      mask_data_field(response)
    end
    response
  end

  def mask_data_field(response)
    return unless response.key?(:data) 

    response[:data]["access_key_id"] = SENSITIVE_DATA_MASK
    response[:data]["secret_access_key"] = SENSITIVE_DATA_MASK
  end

end
# Function to sort array of hashes by a specified key in asc order
def sort_by_key(array, key)
  if array.size >0
    # check the key is a valid field
    unless array[0].key?(key.to_sym)
      raise ApplicationController::BadRequestWithBody, "the sort key #{key} is not a valid field of the issuer object"
    end
    array.sort_by { |hash| hash[key.to_sym] }
  end
end

def create_issuer_policy(policy_fields)
  result_yaml = renderer(PolicyTemplates::CreateIssuer.new, policy_fields)
  set_raw_policy(result_yaml)
  result = load_policy(Loader::CreatePolicy, false, resource)
  policy = result[:policy]
  audit_success(policy)
end

def delete_issuer_policy(policy_fields)
  result_yaml = renderer(PolicyTemplates::DeleteIssuer.new, policy_fields)
  set_raw_policy(result_yaml)
  result = load_policy(Loader::ModifyPolicy, true, resource)
  policy = result[:policy]
  audit_success(policy)
end

def get_issuer_from_db(account, issuer_id)
  Issuer.where(account: account, issuer_id: issuer_id).first
end

def list_issuers_from_db(account)
  Issuer.where(account: account).select(:issuer_id, :max_ttl, :issuer_type, :created_at, :modified_at).all
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

# this function updates the issuer data but 
# reuires the user to call issuer.save 
# This is to save DB calls
def update_issuer_data(params, issuer)
  return unless params.key?(:data)

  issuer.update(data: params[:data].to_json, modified_at: Time.now) 
end

# this function updates the issuer max_ttl but 
# reuires the user to call issuer.save 
# This is to save DB calls
def update_issuer_ttl(params, issuer)
  return unless params.key?(:max_ttl)

  if issuer.max_ttl > params[:max_ttl]
    raise ApplicationController::BadRequestWithBody, "The new max_ttl must be equal or higher than the current max_ttl"
  end

  issuer.update(max_ttl: params[:max_ttl], modified_at: Time.now)
end
