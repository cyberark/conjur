# frozen_string_literal: true

HostBuilder = Struct.new(:account, :id, :owner, :layers, :options) do
  include Loader::Handlers::RestrictedTo
  
  # Find or create the host. If the host exists, the API key is rotated. 
  # Otherwise the host is created. In either case, the host is added to the layers of 
  # the host factory.
  def create_host
    find_and_rotate || create
  end
  
  def host_id
    [ account, "host", id ].join(":")
  end
  
  protected
  
  def find_and_rotate
    host = Role[host_id]
    return nil unless host

    raise Exceptions::Forbidden unless host.resource? && host.resource.owner == owner
    
    # Find-or-create Credentials
    host.api_key
    host.credentials.rotate_api_key
    host.credentials.save
    [ host.resource, host.api_key ]
  end
  
  def create    
    host_p = Conjur::PolicyParser::Types::Host.new
    host_p.id = id
    host_p.account = account
    host_p.owner = Conjur::PolicyParser::Types::Role.new(owner.id)
    host_p.annotations = Hash.new
    (options[:annotations] || {}).each do |k,v|
      host_p.annotations[k] = v.to_s
    end
    
    role_grants = layers.map do |layer|
      Conjur::PolicyParser::Types::Grant.new.tap do |grant_p|
        grant_p.role = Conjur::PolicyParser::Types::Role.new(layer.id)
        grant_p.member = host_p
        grant_p.member.admin = false
      end
    end
    
    policy_objects = [ host_p ] + role_grants
    host = policy_objects.map do |obj|
      Loader::Types.wrap(obj, self).create!
    end.first
    
    store_restricted_to

    ActiveSupport::Notifications.instrument("host_factory_host_created.conjur", this: host)

    [ host, host.role.api_key ]    
  end
end
