# frozen_string_literal: true

class PoliciesController < RestController
  include FindResource
  include AuthorizeResource
  
  before_action :current_user
  before_action :find_or_create_root_policy

  rescue_from Sequel::UniqueConstraintViolation, with: :concurrent_load

  def put
    authorize :update

    load_policy perform_automatic_deletion: true, delete_permitted: true, update_permitted: true
  end

  def patch
    authorize :update

    load_policy perform_automatic_deletion: false, delete_permitted: true, update_permitted: true
  end

  def post
    authorize :create

    load_policy perform_automatic_deletion: false, delete_permitted: false, update_permitted: false
  end

  protected

  def load_policy perform_automatic_deletion:, delete_permitted:, update_permitted:
    policy_text = request.raw_post

    policy_version = PolicyVersion.new \
      role: current_user, policy: resource, policy_text: policy_text
    policy_version.perform_automatic_deletion = perform_automatic_deletion
    policy_version.delete_permitted = delete_permitted
    policy_version.update_permitted = update_permitted
    policy_version.save
    loader = Loader::Orchestrate.new policy_version
    loader.load

    created_roles = loader.new_roles.select do |role|
      %w(user host).member?(role.kind)
    end.inject({}) do |memo, role|
      credentials = Credentials[role: role] || Credentials.create(role: role)
      memo[role.id] = { id: role.id, api_key: credentials.api_key }
      memo
    end

    render json: {
      created_roles: created_roles,
      version: policy_version.version
    }, status: :created
  end

  def find_or_create_root_policy
    Loader::Types.find_or_create_root_policy account
  end

  private

  def concurrent_load _exception
    response.headers['Retry-After'] = retry_delay
    render json: {
      error: {
        code: "policy_conflict",
        message: "Concurrent policy load in progress, please retry"
      }
    }, status: :conflict
  end

  # Delay in seconds to advise the client to wait before retrying on conflict.
  # It's randomized to avoid request bunching.
  def retry_delay
    rand 1..8
  end
end
