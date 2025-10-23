# frozen_string_literal: true

class AuthenticatorController < V2RestController
  include BasicAuthenticator
  include AuthorizeResource

  before_action :set_current_attributes

  class Current < ActiveSupport::CurrentAttributes
    attribute :user
    attribute :request
    # Add other attributes as needed
  end

  def set_current_attributes 
    Current.user = current_user
    Current.request = request
  end

  def list_authenticators
    relevant_params = parse_params(%i[limit offset type account])
    authn_repo = DB::Repository::AuthenticatorRepository.new(
      resource_repository: ::Resource.visible_to(current_user).search(
        **relevant_params.slice(:offset, :limit)
      )
    )
    response = authn_repo.find_all(**relevant_params.slice(:type, :account)).bind do |res|
      count = authn_repo.count_all(**relevant_params.slice(:type, :account))
      Responses::Success.new({ authenticators: res.map(&:to_h), count: count })
    end

    response_audit('list', 'authenticators', response)
    return render(json: response.result) if response.success?

    handle_failure_response(response)
  rescue => e
    failure_audit('list', 'authenticators', e.message)
    log_backtrace(e)
    raise
  end

  def create_authenticator
    relevant_params = parse_params(%i[account])
    valid_body = nil

    response = request_body.bind do |body|
      valid_body = body
      Authenticators::Create.new.call(body, relevant_params[:account])
    end

    type = valid_body&.dig(:type) || 'authenticator'
    name = valid_body&.dig(:name) || ''
    response_audit('create', type, response, resource_id: name)

    return render(json: response.result, status: :created) if response.success?

    handle_failure_response(response)
  rescue => e
    failure_audit('create', 'authenticator', e.message)
    log_backtrace(e)
    raise e
  end

  def find_authenticator
    relevant_params = parse_params(%i[type account service_id])

    response = DB::Repository::AuthenticatorRepository.new(
      resource_repository: ::Resource.visible_to(current_user)
    ).find(**relevant_params)

    response_audit('get', relevant_params[:type], response,  resource_id: relevant_params[:service_id])
    return render(json: response.result.to_h) if response.success?

    handle_failure_response(response)
  rescue => e
    failure_audit('get', relevant_params[:type], e.message,  resource_id: relevant_params[:service_id])
    log_backtrace(e)
    raise
  end

  def authenticator_enablement
    relevant_params = parse_params(%i[type account service_id])
    authn_repo = DB::Repository::AuthenticatorRepository.new(
      resource_repository: ::Resource.visible_to(current_user)
    )

    response = request_body.bind do |body|
      Authenticators::Enablement.from_input(body).bind do |enablement|
        enablement.update_enablement_status(**relevant_params).bind do
          authn_repo.find(**relevant_params)
        end
      end
    end

    response_audit('enable', relevant_params[:type], response, resource_id: relevant_params[:service_id])
    return render(json: response.result.to_h) if response.success?

    handle_failure_response(response)
  rescue => e
    failure_audit('enable', relevant_params[:type], e.message, resource_id: relevant_params[:service_id])
    log_backtrace(e)
    raise
  end

  def delete_authenticator
    relevant_params = parse_params(%i[type account service_id])

    response = Authenticators::Delete.new(
      resource_repository: ::Resource.visible_to(current_user)
    ).call(**relevant_params)

    response_audit('delete', relevant_params[:type], response, resource_id: relevant_params[:service_id])
    return head(response.status) if response.success?

    handle_failure_response(response)
  rescue => e
    failure_audit('delete', relevant_params[:type], e.message, resource_id: relevant_params[:service_id])
    log_backtrace(e)
    raise
  end

  private

  def handle_failure_response(response)
    render(
      json: {
        code: Rack::Utils.status_code(response.status).to_s,
        message: response.message
      },
      status: response.status
    )
  end

  def parse_params(allowed)
    params = allowed_params(allowed)

    # We refer to authenticators by the full authn-<type> format in code rather than the shortened form
    params[:type] = "authn-#{params[:type]}" if params[:type]

    params
  end

  def allowed_params(allowed)
    params.permit(*allowed)
      .slice(*allowed).to_h.symbolize_keys
  end

  def request_body
    return missing_request_body unless req.present?

    Responses::Success.new(
      JSON.parse(
        req,
        {
          symbolize_names: true,
          create_additions: false
        }
      )
    )
  rescue
    Responses::Failure.new(
      "Request JSON is malformed",
      status: :bad_request,
      exception: BadRequestWithBody
    )
  end

  def missing_request_body
    Responses::Failure.new(
      "Request body is empty",
      status: :bad_request
    )
  end

  def req 
    @req ||= request.body.read
  end

  def failure_audit(operation, resource_type, error, resource_id: '')
    audit_event(
      operation,
      resource_type,
      resource_id,
      req.present? ? req : nil,
      error
    )
  end

  def response_audit(operation, resource_type, response, resource_id: '')
    audit_event(
      operation,
      resource_type,
      resource_id,
      req.present? ? req : nil,
      response.success? ? nil : response.message
    )
  end
end
