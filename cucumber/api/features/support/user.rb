# TODO: Move to shared lib
# RoleRepo is one abstraction layer above the sequel model Role.  It allows
# us to perform higher level actions without worrying about implementation
# details, using natural descriptions.
class RoleRepo
  def initialize(
      role_model: Role,
      resource_model: Resource,
      credentials_model: Credentials
  )
    @role_model = role_model
    @resource_model = resource_model
    @credentials_model = credentials_model
  end

  # +create_role+ takes Conjur::Role +role+ object and creates a new role in the
  # database.
  def create_role(role)
    role_id = role.id
    @role_model.create(role_id: role_id).tap do |role|
      @credentials_model.new(role: role).save(raise_on_save_failure: true)
      @resource_model.create(resource_id: role_id, owner: account)
    end
  end

  def entitle(role:, privilege:, on_resource:)
    grantee = @role_model.with_pk!(role.id)
    resource = @resource_model.with_pk!(on_resource)
    resource.permit(privilege, grantee)
  end
end

module RoleRepoModule
  def role_repo
    @role_repo ||= RoleRepo.new
  end

  # TODO: Move to right place
  # Aliases
  def default_admin
    # TODO: Maybe RoleId?
    Conjur::Role.new(account: "!", kind: :user, name: "admin")
  end
end

World(RoleRepoModule)
