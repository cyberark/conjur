class Role < Sequel::Model
  unrestrict_primary_key

  one_to_many :memberships, class: :RoleMembership
  one_to_many :memberships_as_member, class: :RoleMembership, key: :member_id
  one_to_one  :credentials, reciprocal: :role
  
  plugin :json_id_serializer
  
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
