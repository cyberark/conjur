class Role < Sequel::Model
  unrestrict_primary_key

  one_to_many :memberships, class: :RoleMembership
  one_to_many :memberships_as_member, class: :RoleMembership, key: :member_id
  one_to_one  :credentials, reciprocal: :role
  
  alias id role_id

  def as_json options = {}
    options[:exclude] ||= []
    options[:exclude] << :credentials
      
    super(options).tap do |response|
      response["id"] = response.delete("role_id")
    end
  end
  
  class << self
    def make_full_id id
      tokens = id.split(":") rescue []
      account, kind, id = if tokens.size < 2
        raise ArgumentError, "Expected at least 2 tokens in #{id}"
      elsif tokens.size == 2
        [ Conjur::Rack.user.account ] + tokens
      elsif tokens.size >= 3
        [ tokens[0], tokens[1], tokens[2..-1].join(':') ]
      end
      [ account, kind, id ].join(":")
    end

    def roleid_from_username login
      tokens = login.split('/',2)
      tokens.unshift  'user' if tokens.length == 1
      tokens.unshift default_account
      tokens.join(":")
    end
    
    def username_from_roleid roleid
      account, kind, id = roleid.split(":", 3)
      raise "Expected account #{account} to be #{default_account}" unless account == default_account
      if kind == 'user'
        id
      else
        [ kind, id ].join('/')
      end
    end
  end
  
  def password= password
    self.credentials ||= Credentials.new(role: self)
    self.credentials.password = password
    self.credentials.save(raise_on_save_failure: true)
  end
  
  def api
    require 'conjur/api'
    Conjur::API.new_from_key login, api_key
  end
  
  def api_key
    unless self.credentials
      account, kind, id = self.id.split(":", 3)
      if %w(user host deputy).member?(kind)
        self.credentials = Credentials.create(role: self)
      else
        raise "Role #{id} has no credentials" 
      end
    end
    self.credentials.api_key
  end
  
  def login
    account, kind, id = self.id.split(":", 3)
    raise "Cannot login as non-default account" unless account == default_account
    if kind == "user"
      id
    else
      [ kind, id ].join('/')
    end
  end
  
  def resource
    Resource[id] or raise "Resource not found for #{id}"
  end
  
  def grant_to member, options = {}
    options[:admin_option] ||= false
    options[:member] = member
      
    add_membership options
  end
  
  def allowed_to? privilege, resource
    Role.from(Sequel.function(:is_role_allowed_to, id, privilege, resource.id)).first[:is_role_allowed_to]
  end
  
  def self.that_can permission, resource
    Role.from(::Sequel.function(:roles_that_can, permission.to_s, resource.pk))
  end
end
