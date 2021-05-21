module ResourceHelpers
  include FullId

  attr_reader :result

  def get_resource kind, id=nil
    resource_client(kind, id).get(:Authorization => create_token_header())
  end

  def get_privilaged_roles kind, id, privilege
    resource_client(kind, id).get(:Authorization => create_token_header(), params: {permitted_roles: true, privilege: privilege})
  end

  def add_secret token, kind, id, value
    secrets_client(kind,id).post(value, :Authorization => create_token_header())
  end

  def get_secret token, kind, id
    secrets_client(kind,id).get(:Authorization => create_token_header(token))
  end

  def get_roles kind, id
    role_client(kind, id).get(:Authorization => create_token_header())
  end

  def secrets_client kind, id
    RestClient::Resource.new(uri('secrets', kind, id) , 'Content-Type' => 'application/json')
  end

  def role_client kind, id
    RestClient::Resource.new(uri('roles', kind, id), 'Content-Type' => 'application/json')
  end

  def resource_client kind, id=nil
    RestClient::Resource.new(uri('resources', kind, id), 'Content-Type' => 'application/json')
  end

end
World(ResourceHelpers)