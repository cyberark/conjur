# frozen_string_literal: true

require_relative '../controllers/wrappers/policy_wrapper'
require_relative '../controllers/wrappers/policy_audit'
require_relative '../controllers/wrappers/templates_renderer'
require_relative '../domain/issuers/issuer_types/issuer_type_factory'
#
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

  def create
    logger.info(LogMessages::Endpoints::EndpointRequested.new("POST issuers/#{params[:account]}"))
    action = :create
    authorize(action, resource)

    issuer_type = IssuerTypeFactory.new.create_issuer_type(params[:type])
    issuer_type.validate(body_params)

    issuer = Issuer.new(issuer_id: params[:id], account: params[:account],
                        issuer_type: params[:type],
                        max_ttl: params[:max_ttl], data: params[:data].to_json,
                        modified_at: Sequel::CURRENT_TIMESTAMP,
                        policy_id: "#{params[:account]}:policy:conjur/issuers/#{params[:id]}")

    raise ApplicationController::InternalServerError, "Found related variable/s to the given issuer id" if issuer.issuer_variables_exist?

    create_issuer_policy({ "id" => params[:id] })
    issuer.save
    issuer_audit_success(issuer.account, issuer.issuer_id, "add")

    render(json: issuer.as_json, status: :created)

    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("POST issuers/#{params[:account]}"))
  rescue Exceptions::RecordNotFound => e
    logger.error(LogMessages::Issuers::IssuerEndpointForbidden.new("create"))
    audit_failure(e, action)
    issuer_audit_failure(params[:account], params[:id], "add", e.message)
    raise Exceptions::Forbidden, "issuers"
  rescue ApplicationController::BadRequest => e
    logger.error("Input validation error for issuer [#{params[:id]}]: #{e.message}")
    audit_failure(e, action)
    render(json: {
      error: {
        code: "bad_request",
        message: e.message
      }
    }, status: :bad_request)
  rescue Sequel::UniqueConstraintViolation => e
    logger.error("Issuer [#{params[:id]}] already exists")
    audit_failure(e, action)
    issuer_audit_failure(params[:account], params[:id], "add", e.message)
    raise Exceptions::RecordExists.new("issuer", params[:id])
  rescue => e
    audit_failure(e, action)
    issuer_audit_failure(params[:account], params[:id], "add", e.message)
    logger.error(LogMessages::Conjur::GeneralError.new(e.message))
    head :internal_server_error
  end

  def delete
    logger.info(LogMessages::Endpoints::EndpointRequested.new("DELETE issuers/#{params[:account]}/#{params[:identifier]}"))
    action = :update
    authorize(action, resource)

    issuer = get_issuer_from_db(params[:account], params[:identifier])
    if issuer
      # Deleting the issuer policy causes a cascade delete of the issuers object as well
      # But we need to delete the issuer related variables so that we won't leave orphans
      deleted_variables = issuer.delete_issuer_variables
      delete_issuer_policy({ "id" => params[:identifier] })
      issuer_audit_success(issuer.account, issuer.issuer_id, "remove")
      issuer_variables_audit_delete(issuer.account, issuer.issuer_id, deleted_variables)
      head :ok
    else
      raise Exceptions::RecordNotFound.new(params[:identifier], message: ISSUER_NOT_FOUND)
    end

    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("DELETE issuers/#{params[:account]}/#{params[:identifier]}"))
  rescue Exceptions::RecordNotFound => e
    logger.error(LogMessages::Issuers::IssuerPolicyNotFound.new(resource_id))
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
    logger.info(LogMessages::Endpoints::EndpointRequested.new("GET issuers/#{params[:account]}/#{params[:identifier]}"))
    # If I can update the issuer policy, it means I am allowed to view it as well
    action = :update
    authorize(action, resource)

    issuer = get_issuer_from_db(params[:account], params[:identifier])
    if issuer
      issuer_audit_success(issuer.account, issuer.issuer_id, "fetch")
      render(json: issuer.as_json, status: :ok)
    else
      # issuer_audit_failure(issuer.account, issuer.issuer_id, "get", ISSUER_NOT_FOUND)
      raise Exceptions::RecordNotFound.new(params[:identifier], message: ISSUER_NOT_FOUND)
    end

    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("GET issuers/#{params[:account]}/#{params[:identifier]}"))
  rescue Exceptions::RecordNotFound => e
    issuer_audit_failure(params[:account], params[:identifier], "fetch", ISSUER_NOT_FOUND)
    logger.error(LogMessages::Issuers::IssuerPolicyNotFound.new(resource_id))
    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("GET issuers/#{params[:account]}/#{params[:identifier]}"))
    raise Exceptions::RecordNotFound.new(params[:identifier], message: ISSUER_NOT_FOUND)
  rescue => e
    issuer_audit_failure(params[:account], params[:identifier], "fetch", e.message)
    logger.error(LogMessages::Conjur::GeneralError.new(e.message))
    raise e
  end

  def list
    logger.info(LogMessages::Endpoints::EndpointRequested.new("GET issuers/#{params[:account]}"))
    # If I can update the issuer policy, it means I am allowed to view it as well
    action = :update
    authorize(action, resource)

    issuers = list_issuers_from_db(params[:account])
    result = []
    issuers.each do |item|
      result.push(item.as_json)
    end
    issuer_audit_success(params[:account], "*", "list")
    render(json: { issuers: result }, status: :ok)

    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("GET issuers/#{params[:account]}"))
  rescue Exceptions::RecordNotFound => e
    logger.error(LogMessages::Issuers::IssuerEndpointForbidden.new("list"))
    issuer_audit_failure(params[:account], "*", "list", e.message)
    raise Exceptions::Forbidden, "issuers"
  rescue => e
    issuer_audit_failure(params[:account], "*", "list", e.message)
    logger.error(LogMessages::Conjur::GeneralError.new(e.message))
    raise e
  end
end

private

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
