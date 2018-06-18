class RolesController < RestController
  include AuthorizeResource

  before_filter :current_user

  def show
    render json: role.as_json.merge(members: role.memberships)
  end

  # Find all role memberships, expanded recursively. If no parameters
  # are given, the role id of each membership is returned.
  #
  # If +params[:filter]+ is given, return (as role ids), the subset of
  # memberships that matches the filter
  #
  # If +params[:count]+ is given, return the count of memberships,
  # rather than the memberships themselves
  #
  def all_memberships
    memberships = filtered_roles(role.all_roles, membership_filter)
    render_dataset(memberships) { |dataset| dataset.map(&:role_id) }
  end

  # Find all direct memberships, i.e don't recursively expand member
  # roles.
  #
  # For each membership, return the full details of the grant as a
  # JSON object.
  # 
  #
  # +params[:filter]+ and +params[:count]+ are handled as for +#all_memberships+
  #
  def direct_memberships
    memberships = filtered_roles(role.memberships_as_member_dataset, membership_filter)
    render_dataset(memberships)
  end
  
  # Find all members of this role.
  #
  # For each member, return the full details of the grant as a
  # JSON object
  #
  # +params[:count] returns only the number of members
  # +params[:limit] and [:offset] control the paging
  # +params[:search] returns only the members that match the search string
  # +params[:kind] (array) returns only the members that match the specified kinds
  def members
    members = role.members_dataset(filter_params)
    render_dataset(members) { |dataset| dataset.result_set(render_params) }
  end

  # Returns a graph of the roles anchored on the current Role
  def graph
    render json: role.graph
  end

  # update_member will add or modify an existing role membership
  #
  # This API endpoint exists to manage group entitlements through
  # the UI or other integrations outside of loading a policy.
  def add_member
    authorize(:create, policy)

    member_id = params[:member]
    member = Role[member_id]
    raise Exceptions::RecordNotFound, member_id unless member

    role.grant_to member

    # TODO: Record audit event
    
    head :no_content
  end

  # delete_member will delete a role membership
  #
  # This API endpoint exists to manage group entitlements through
  # the UI or other integrations outside of loading a policy.
  def delete_member
    authorize(:update, policy)

    member_id = params[:member]
    membership = role.memberships_dataset.where(member_id: member_id).first
    raise Exceptions::RecordNotFound, member_id unless membership

    membership.destroy

    # TODO: Record audit event

    head :no_content
  end

  protected

  def policy
    resource.policy
  end

  def resource
    Resource[role_id]
  end

  def role
    @role ||= Role[role_id]
    raise Exceptions::RecordNotFound, role_id unless @role
    return @role
  end

  def role_id
    [ params[:account], params[:kind], params[:identifier] ].join(":")
  end

  def filter_params
    request.query_parameters.slice(:search, :kind).symbolize_keys
  end
  
  def render_params
    params.slice(:limit, :offset).symbolize_keys
  end

  def membership_filter        
    filter = params[:filter]
    filter = Array(filter).map{ |id| Role.make_full_id id, account } if filter
    return filter
  end

  def filtered_roles(roles, filter)
    filter ? roles.member_of(filter) : roles
  end

  def render_dataset(dataset, &block)
    resp = count_only?  ? count_payload(dataset) :
           block_given? ? yield(dataset)         : dataset.all

    render json: resp    
  end

  def count_only?
    params.key?(:count)
  end

  def count_payload(dataset)
    { count: dataset.count }
  end


end
