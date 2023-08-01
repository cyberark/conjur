# frozen_string_literal: true

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

  protected

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
