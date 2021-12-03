# frozen_string_literal: true

# REST endpoints for persisting authenticator configuration details in Conjur
class AuthenticatorsController < RestController
  include FindResource
  include AuthorizeResource
  
  before_action :current_user
  before_action :parse_request_body

  rescue_from Sequel::UniqueConstraintViolation, with: :concurrent_load

  def persist_auth
    conjur_policy_branch = find_or_create_conjur_policy_branch
    policy_exists = policy_resource_exists?(auth_policy_branch)
    policy_details = Authentication::PersistAuthFactory.new_from_authenticator(authenticator).(
      conjur_account: params[:account],
      service_id: service_id,
      resource: conjur_policy_branch,
      current_user: current_user,
      client_ip: request.ip,
      request_data: @request_data
    )
    render(body: policy_text(policy_details), content_type: "text/yaml", status: policy_exists ? :ok : :created)
  end

  protected

  def find_or_create_conjur_policy_branch
    ::Resource[conjur_policy_branch_name] || create_conjur_policy_branch
  end

  private

  def create_conjur_policy_branch
    ::Role.create(role_id: conjur_policy_branch_name)
    ::Resource.create(resource_id: conjur_policy_branch_name, owner: ::Role["#{account}:user:admin"])
  end

  def conjur_policy_branch_name
    "#{account}:policy:conjur"
  end

  def policy_text(loaded_policy_details)
    loaded_policy_details[:policy].values[:policy_text]
  end

  def policy_resource_exists?(policy_branch_name)
    Resource["#{params[:account]}:policy:#{policy_branch_name}"] ? true : false
  end

  def auth_policy_branch
    "conjur/#{authenticator}/#{service_id}"
  end

  def service_id
    # Returns a default service id of "authenticator" if none is provided
    @service_id ||= params.fetch(:service_id, "authenticator")
  end

  def parse_request_body
    @request_data = if request.raw_post != ''
      JSON.parse(request.raw_post)
    else
      {}
    end
  rescue JSON::JSONError => e
    raise UnprocessableEntity, e.message
  end

  def authenticator
    @authenticator ||= params[:authenticator]
  end

  def retry_delay
    rand(1..8)
  end

  def concurrent_load(_exception)
    response.headers['Retry-After'] = retry_delay
    render(json: {
      error: {
        code: "policy_conflict",
        message: "Concurrent policy load in progress, please retry"
      }
    }, status: :conflict)
  end
end
