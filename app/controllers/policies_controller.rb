# frozen_string_literal: true
require 'command_class'

class PoliciesController < RestController
  include FindResource
  include AuthorizeResource
  
  before_action :current_user
  before_action :find_or_create_root_policy

  rescue_from Sequel::UniqueConstraintViolation, with: :concurrent_load

  # Conjur policies are YAML documents, so we assume that if no content-type
  # is provided in the request.
  set_default_content_type_for_path(%r{^/policies}, 'application/x-yaml')

  def put
    load_policy(:update, Loader::ReplacePolicy, true)
  end

  def patch
    load_policy(:update, Loader::ModifyPolicy, true)
  end

  def post
    load_policy(:create, Loader::CreatePolicy, false)
  end

  def initialize_k8s_auth
    auth_data = Authentication::AuthnK8s::K8sAuthenticatorData.new(JSON.parse(request.raw_post))
    Authentication::InitializeAuth.new.(
      conjur_account: params[:account],
      service_id: params[:service_id],
      resource: find_or_create_root_policy,
      current_user: current_user,
      client_ip: request.ip,
      auth_data: auth_data
    )
  end

  def initialize_azure_auth
    params[:authenticator] = "authn-azure"
    require_body_parameters("provider-uri")
    initialize_auth_policy(template: params[:authenticator])

    Secret.create(resource_id: variable_id('provider-uri'), value: json_body['provider-uri'])
  rescue => e
    audit_failure(e, :update)
    raise e
  end

  def initialize_oidc_auth
    params[:authenticator] = "authn-oidc"
    require_body_parameters("provider-uri", "id-token-user-property")
    initialize_auth_policy(template: params[:authenticator])

    Secret.create(resource_id: variable_id('provider-uri'), value: json_body['provider-uri'])
    Secret.create(resource_id: variable_id('id-token-user-property'), value: json_body['id-token-user-property'])
  rescue => e
    audit_failure(e, :update)
    raise e
  end

  protected

  # Returns newly created roles
  def perform(policy_action)
    policy_action.call
    new_actor_roles = actor_roles(policy_action.new_roles)
    create_roles(new_actor_roles)
  end

  def find_or_create_root_policy
    Loader::Types.find_or_create_root_policy(account)
  end

  private

  def load_policy(action, loader_class, delete_permitted)
    details = Policy::LoadPolicy.new(loader_class: loader_class).(
      delete_permitted: delete_permitted,
      action: action,
      resource: resource,
      policy_text: request.raw_post,
      current_user: current_user,
      client_ip: request.ip
    )

    render(json: {
      created_roles: details[:created_roles],
      version: details[:policy].version
    }, status: :created)
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
