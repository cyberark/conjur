HostBuilder = Struct.new(:account, :id, :owner, :layers, :options) do
  
  # Find or create the host. If the host exists, the API key is rotated. 
  # Otherwise the host is created. In either case, the host is added to the layers of 
  # the host factory.
  def create_host
    host_id = [ account, "host", id ].join(":")
    host = Resource[host_id]
    if host.exists?
      host.credentials.rotate_api_key
      host.credentials.save
      return [ host, host.api_key ]
    end

    host_p = Conjur::Policy::Types::Host.new
    host_p.id = id
    host_p.account = account
    host_p.owner = Conjur::Policy::Types::Role.new(owner.id)
    (options[:annotations] || {}).each do |k,v|
      host_p.annotations[k] = v.to_s
    end
    
    role_grants = layers.map do |layer|
      Conjur::Policy::Types::Grant.new.tap do |grant_p|
        grant_p.role = Conjur::Policy::Types::Role.new(layer.id)
        grant_p.member = host_p
      end
    end
    
    policy_objects = [ host_p ] + role_grants
    policy_objects.each do |obj|
      Loader::Types.wrap(obj).create!
    end
  end
end
