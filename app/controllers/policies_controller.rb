class PoliciesController < RestController
  include FindResource
  include AuthorizeResource
  
  before_filter :current_user
  before_filter :find_or_create_bootstrap_policy
  before_filter :find_resource

  def show
    authorize :read

    version = params[:version]
    policy_version = if version.is_a?(String) && version.to_i.to_s == version
      PolicyVersion[resource: @resource, version: version]
    elsif version.nil?
      PolicyVersion.where(resource: @resource).reverse_order(:version).limit(1).first
    else
      raise ArgumentError, "invalid type for parameter 'version'"
    end
    raise Exceptions::RecordNotFound, @resource.id, "Requested version does not exist" if policy_version.nil?

    render text: policy_version.policy_text
  end
  
  def load
    force = params[:force]

    if force
      authorize :update
    else
      authorize :execute
    end

    policy_text = request.raw_post
    raise ArgumentError, "policy text may not be empty" if policy_text.blank?

    policy_version = PolicyVersion.new role: current_user, policy: @resource, policy_text: policy_text
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

  protected

  def find_or_create_bootstrap_policy
    Loader::Types.find_or_create_bootstrap_policy account
  end
end
