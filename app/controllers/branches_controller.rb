# frozen_string_literal: true

require_relative '../domain/branch/domain'
require_relative '../domain/branch/validation'

class BranchesController < V2RestController
  include FindResource
  include AuthorizeResource
  include BodyParser
  include Domain
  include Validation

  def initialize(
    *args,
    branch_service: BranchService.instance,
    owner_service: OwnerService.instance,
    res_repo: ::Resource,
    role_repo: ::Role,
    **kwargs
  )
    super(*args, **kwargs)

    @branch_service = branch_service
    @owner_service = owner_service
    @res_repo = res_repo
    @role_repo = role_repo
  end

  def create
    input = permit_create_params(params)
    branch = Branch.from_input(input)

    authorize_create_in_parent(branch)
    check_branch_not_conflict(branch)
    check_owner_exists_if_set(branch.owner)

    render(json: create_branch(branch), status: :created)
    audit_fine(:create, branch.identifier, body_str)
  rescue DomainValidationError => e
    audit_creating_failure(params, e.message)
    raise ApplicationController::UnprocessableEntity, e.message
  end

  def show
    authorize_read(path_identifier)
    render(json: read_branch(path_identifier))
    audit_fine(:get)
  end

  def index
    input = permit_index_params(params)
    response = read_branches(Paging.new(input), 'root')
    render(json: response)
  end

  def update
    input = permit_update_params(params)
    # body_payload has values set after params method call
    validate_update_payload(body_payload)
    authorize_update(path_identifier)
    branch_up = BranchUpPart.from_input(input)

    check_owner_exists_if_set(branch_up.owner)

    updated_branch = update_branch(branch_up, path_identifier)
    render(json: updated_branch)
    audit_fine(:patch)
  rescue DomainValidationError => e
    audit_creating_failure(params, e.message)
    raise ApplicationController::UnprocessableEntity, e.message
  end

  def delete
    authorize_parent_for_del(path_identifier)
    delete_branch(path_identifier)
    head(:no_content)
    audit_fine(:delete)
  end

  private

  # create

  def permit_create_params(params)
    params.permit(
      :account, :name, :branch,
      owner: %i[kind id], annotations: {}
    ).to_h.deep_transform_keys(&:to_sym)
  end

  def authorize_create_in_parent(branch)
    get_and_auth_policy(:create, branch.branch)
  end

  def check_branch_not_conflict(branch)
    @branch_service.check_branch_not_conflict(account, branch.identifier)
  end

  def check_owner_exists_if_set(owner)
    return unless owner.set?

    @owner_service.check_owner_exists(account, owner)
  end

  def create_branch(branch)
    @branch_service.check_parent_branch_exists(account, branch.branch)
    @branch_service.create_branch(account, branch)
  end

  # show

  def authorize_read(identifier)
    get_and_auth_policy(:read, identifier)
  end
  
  def read_branch(identifier)
    @branch_service.check_parent_branch_exists(account, identifier)
    @branch_service.read_branch(account, identifier)
  end

  # index

  def permit_index_params(params)
    allowed_params = %i[offset limit]
    params.permit(*allowed_params).to_h.symbolize_keys
  end

  def read_branches(paging, identifier)
    @branch_service.check_parent_branch_exists(account, identifier)
    @branch_service.read_branches(account, current_user.role_id, paging, identifier)
  end

  # update

  def permit_update_params(params)
    params.permit(
      :account, :identifier,
      owner: %i[kind id], annotations: {}
    ).to_h.deep_transform_keys(&:to_sym)
  end

  def authorize_update(identifier)
    get_and_auth_policy(:read, identifier)
    get_and_auth_policy(:update, identifier)
  end

  def validate_update_payload(body_json)
    raise DomainValidationError, 'Empty request body' if body_json.empty?

    body_json.each_key do |key|
      unless %i[owner annotations].include?(key.to_sym)
        raise DomainValidationError, "Invalid input field: #{key}"
      end
    end
  end

  def update_branch(branch_up, identifier)
    @branch_service.check_parent_branch_exists(account, path_identifier)
    @branch_service.update_branch(account, branch_up, identifier)
  end

  # delete

  def authorize_parent_for_del(identifier)
    get_and_auth_policy(:update, res_identifier(identifier))
  end

  def delete_branch(identifier)
    @branch_service.check_parent_branch_exists(account, identifier)
    @branch_service.delete_branch(account, current_user, identifier)
  end

  # audit

  def audit_fine(action, identifier = nil,  body_json_str = nil)
    audit_success('branch', action.to_s, identifier || path_identifier, body_json_str)
  end

  def audit_creating_failure(params, err_msg)
    parent_identifier = params[:branch]
    name = params[:name]
    identifier = parent_identifier && name ? to_identifier(parent_identifier, name) : ""
    audit_failure('branch', 'create', identifier, err_msg, body_str)
  end

  # policy

  def get_and_auth_policy(action, identifier)
    policy = get_policy(identifier)
    authorize(action, policy)
    policy
  rescue ApplicationController::Forbidden, Exceptions::RecordNotFound => e
    audit_creating_failure(params, e.message)
    raise Exceptions::RecordNotFound, full_id(account, 'branch', identifier)
  end

  def get_policy(identifier)
    get_resource('policy', identifier)
  end
end
