# frozen_string_literal: true

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
    def host_key(account)
      "authn:#{account}:host"
    end
    def user_key(account)
      "authn:#{account}:user"
    end
    def create(id, owner_id = nil)
      raise Exceptions::RecordExists.new("account", id) if Slosilo[host_key(id)] or Slosilo[user_key(id)]

      if (invalid = INVALID_ID_CHARS.match(id))
        raise ArgumentError, 'account name "%s" contains invalid characters (%s)' % [id, invalid]
      end

      Role.db.transaction do
        Slosilo[host_key(id)] = Slosilo::Key.new
        Slosilo[user_key(id)] = Slosilo::Key.new

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
      accounts = []
      Slosilo.each do |k,v|
        accounts << k
      end
      accounts.map do |account|
        account =~ /\Aauthn:(.+)\z/
        $1
      end.delete_if do |account|
        account == "!"
      end
    end
  end

  def token_key_host
    Slosilo["authn:#{id}:host"]
  end

  def token_key_user
    Slosilo["authn:#{id}:user"]
  end

  def delete
    # Ensure the signing key exists
    slosilo_keystore.adapter.model.with_pk!(token_key_host)
    slosilo_keystore.adapter.model.with_pk!(token_key_user)
    Role["#{id}:user:admin"].destroy
    Role["#{id}:policy:root"].try(:destroy)
    Resource["#{id}:user:admin"].try(:destroy)
    Credentials.where(Sequel.lit("account(role_id)") => id).delete
    Secret.where(Sequel.lit("account(resource_id)") => id).delete
    slosilo_keystore.adapter.model[token_key_host].destroy
    slosilo_keystore.adapter.model[token_key_user].destroy
    true
  end

  protected

  def slosilo_keystore
    Slosilo.send(:keystore)
  end



end
