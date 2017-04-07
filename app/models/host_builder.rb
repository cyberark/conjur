HostBuilder = Struct.new(:account, :id, :owner, :layers, :options) do
  
  # Find or create the host. If the host exists, the API key is rotated. 
  # Otherwise the host is created. In either case, the host is added to the layers of 
  # the host factory.
  def create_host
    host_id = [ account, "host", id ].join(":")
    if host = Role[host_id]
      raise Exceptions::Forbidden unless host.resource.owner == owner
      
      # Find-or-create Credentials
      host.api_key
      host.credentials.rotate_api_key
      host.credentials.save
      
      return [ host.resource, host.api_key ]
    end
    
    host_p = Conjur::Policy::Types::Host.new
    host_p.id = id
    host_p.account = account
    host_p.owner = Conjur::Policy::Types::Role.new(owner.id)
    host_p.annotations = Hash.new
    (options[:annotations] || {}).each do |k,v|
      host_p.annotations[k] = v.to_s
    end
    
    role_grants = layers.map do |layer|
      Conjur::Policy::Types::Grant.new.tap do |grant_p|
        grant_p.role = Conjur::Policy::Types::Role.new(layer.id)
        grant_p.member = host_p
        grant_p.member.admin = false
      end
    end
    
    policy_objects = [ host_p ] + role_grants
    host = policy_objects.map do |obj|
      Loader::Types.wrap(obj).create!
    end.first
    
    [ host, host.role.api_key ]    
  end
end
