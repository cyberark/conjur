# frozen_string_literal: true
require_relative '../../gems/conjur-rack/lib/conjur/rack/consts'

Account = Struct.new(:id) do
  class << self
    def find_or_create_accounts_resource
      unless Slosilo["authn:!"]
        pkey = Slosilo::Key.new
        Slosilo["authn:!"] = pkey
      end

      role_id     = "!:!:root"
      resource_id = "!:webservice:accounts"
      (role = Role[role_id]) || Role.create(role_id: role_id)
      Resource[resource_id] ||
        Resource.create(resource_id: resource_id, owner_id: role_id)
    end

    INVALID_ID_CHARS = /[ :]/.freeze

    def token_key(account, role, tag = "current")
      Slosilo[token_id(account, role, tag)]
    end

    def token_id(account, role, tag = "current")
      "authn:#{account}:#{role}:#{tag}"
    end

    def create(id, owner_id = nil)
      raise Exceptions::RecordExists.new("account", id) if token_key(id, "host") || token_key(id, "user")

      if (invalid = INVALID_ID_CHARS.match(id))
        raise ArgumentError, 'account name "%s" contains invalid characters (%s)' % [id, invalid]
      end

      Role.db.transaction do
        Slosilo[token_id(id, "host")] = Slosilo::Key.new
        Slosilo[token_id(id, "user")] = Slosilo::Key.new

        role_id = "#{id}:user:admin"
        admin_user = Role.create(role_id: role_id)

        # Ensure a resource record exists for the admin role so that permissions
        # work as expected. If one isn't given, the admin will own itself.
        owner_id ||= role_id
        Resource.create(resource_id: role_id, owner_id: owner_id)

        admin_user.api_key
      end
    end

    def list
      account_set = Set.new
      Slosilo.each do |account,_|
        account =~ Conjur::Rack::Consts::TOKEN_ID_REGEX
        account_set.add($1) unless $1 == "!"
      end
      account_set
    end
  end

  def token_key(role)
    Account.token_key(id, role)
  end

  def token_id(role)
    Account.token_id(id, role)
  end

  def delete
    # Ensure the signing key exists
    slosilo_keystore.adapter.model.with_pk!(token_id("user"))
    slosilo_keystore.adapter.model.with_pk!(token_id("host"))
    Role["#{id}:user:admin"].destroy
    Role["#{id}:policy:root"].try(:destroy)
    Resource["#{id}:user:admin"].try(:destroy)
    Credentials.where(Sequel.lit("account(role_id)") => id).delete
    Secret.where(Sequel.lit("account(resource_id)") => id).delete
    slosilo_keystore.adapter.model[token_id("user")].destroy
    slosilo_keystore.adapter.model[token_id("host")].destroy
    true
  end

  protected

  def slosilo_keystore
    Slosilo.send(:keystore)
  end
end
