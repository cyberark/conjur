# frozen_string_literal: true

# REST endpoints for persisting authenticator configuration details in Conjur
class AuthenticatorsController < RestController
  include FindResource
  include AuthorizeResource
  
  before_action :current_user
  before_action :find_or_create_root_policy
  before_action :parse_request_body

  rescue_from Sequel::UniqueConstraintViolation, with: :concurrent_load

  def persist_auth
    policy_exists = policy_resource_exists(auth_policy_branch)
    policy_details = Authentication::PersistAuthFactory.new_from_authenticator(params[:authenticator]).(
      conjur_account: params[:account],
      service_id: service_id,
      resource: find_or_create_root_policy,
      current_user: current_user,
      client_ip: request.ip,
      request_data: @request_data
    )
    render(body: policy_text(policy_details), content_type: "text/yaml", status: policy_exists ? :ok : :created)
  end

  # Endpoint takes a JSON body containing two keys:
  # id=the new hosts id & annotations=JSON object w/key/values being annotations to add to the host
  def persist_auth_host
    policy_exists = policy_resource_exists(auth_host_policy_branch)
    policy_details = Authentication::PersistAuthHost.new.(
      conjur_account: params[:account],
      service_id: service_id,
      authenticator: params[:authenticator],
      resource: find_or_create_root_policy,
      current_user: current_user,
      client_ip: request.ip,
      host_data: host_details
    )
    render(body: policy_text(policy_details), content_type: "text/yaml", status: policy_exists ? :ok : :created)
  end

  def persist_gcp_auth
    raise UnprocessableEntity, "GCP authenticatior takes no arguments" unless @request_data.empty?

    policy_exists = policy_resource_exists(auth_policy_branch)
    policy_details = Authentication::PersistAuthFactory.new_from_authenticator("authn-gcp").(
      conjur_account: params[:account],
      service_id: service_id,
      resource: find_or_create_root_policy,
      current_user: current_user,
      client_ip: request.ip,
      request_data: {}
    )
    render(body: policy_text(policy_details), content_type: "text/yaml", status: policy_exists ? :ok : :created)
  end

  def persist_gcp_auth_host
    policy_exists = policy_resource_exists(auth_host_policy_branch)
    policy_details = Authentication::PersistAuthHost.new.(
      conjur_account: params[:account],
      service_id: service_id,
      authenticator: "authn-gcp",
      resource: find_or_create_root_policy,
      current_user: current_user,
      client_ip: request.ip,
      host_data: host_details(authenticator: "authn-gcp")
    )
    render(body: policy_text(policy_details), content_type: "text/yaml", status: policy_exists ? :ok : :created)
  end

  protected

  def find_or_create_root_policy
    Loader::Types.find_or_create_root_policy(account)
  end

  private

  def policy_text(loaded_policy_details)
    loaded_policy_details[:policy].values[:policy_text]
  end

  def policy_resource_exists(policy_branch_name)
    Resource[format("%s:policy:%s", params[:account], policy_branch_name)] ? true : false
  end

  def auth_host_policy_branch
    format("%s/apps", auth_policy_branch)
  end

  def auth_policy_branch
    branch_format_string = "conjur/%s/%s"
    format(branch_format_string, params[:authenticator], service_id)
  end

  def service_id
    if params[:service_id].nil?
      "authenticator"
    else
      params[:service_id]
    end
  end

  def host_details(authenticator: params[:authenticator])
    Authentication::AuthHostDetailsFactory.new_from_authenticator(authenticator, @request_data)
  end

  def parse_request_body
    @request_data = if request.raw_post.empty?
      {}
    else
      JSON.parse(request.raw_post)
    end
  rescue JSON::JSONError => e
    raise UnprocessableEntity, e.message
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
