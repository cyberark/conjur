module ResourceHelpers
  include FullId

  attr_reader :result

  def get_resource(kind, id = nil)
    client(uri('resources', kind, id)).get(header)
  end

  def get_privilaged_roles(kind, id, privilege)
    client(uri('resources', kind, id)).get(
      header.merge(params: { permitted_roles: true, privilege: privilege })
    )
  end

  def add_secret(token, kind, id, value)
    client(uri('secrets', kind, id)).post(value, header(token))
  end

  def get_secret(token, kind, id)
    client(uri('secrets', kind, id)).get(header(token))
  end

  def get_roles(kind, id)
    client(uri('roles', kind, id)).get(header)
  end

  def client(url)
    RestClient::Resource.new(url, 'Content-Type' => 'application/json')
  end

end

World(ResourceHelpers)
