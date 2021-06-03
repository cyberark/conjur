module ResourceHelpers
  include FullId

  attr_reader :result

  def get_resource(kind, id = nil)
    resource_helpers('resources', kind, id).fetch_resource
  end

  def get_privilaged_roles(kind, id, privilege)
    resource_helpers('resources', kind, id).fetch_privilaged_roles(
      params: { permitted_roles: true, privilege: privilege }
    )
  end

  def add_secret( kind, id, value, token)
    resource_helpers('secrets', kind, id).add_secret(value, token)
  end

  def get_secret( kind, id, token)
    resource_helpers('secrets', kind, id).fetch_secret(token)
  end

  def get_roles(kind, id)
    resource_helpers('roles', kind, id).fetch_resource
  end

  def get_public_keys(username)
    resource_helpers('public_keys', 'user', username).fetch_resource
  end

  def resource_helpers(root, kind, id)
    ClientHelpers::ResourceHelper::ResourceClient.new(root, kind, id)
  end

end

World(ResourceHelpers)
