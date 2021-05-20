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
    RestClient::Resource.new(appliance_url() + '/secrets/' + account() + '/' + kind +'/'+ id , 'Content-Type' => 'application/json')
  end

  def role_client kind, id
    RestClient::Resource.new(appliance_url() + '/roles/' + account() + '/' + kind + '/'+ id, 'Content-Type' => 'application/json')
  end

  def resource_client kind, id=nil
    uri = ""
    if id==nil
      uri = appliance_url() + '/resources/' + account() + '/' + kind
    else
      uri =appliance_url() + '/resources/' + account() + '/' +kind +'/'+ id
    end
    RestClient::Resource.new(uri, 'Content-Type' => 'application/json')
  end

end
World(ResourceHelpers)