Account = Struct.new(:id) do
  class << self
    def find_or_create_accounts_resource
      unless Slosilo["authn:!"]
        pkey = Slosilo::Key.new
        Slosilo["authn:!"] = pkey
      end
  
      role_id     = "!:!:root"
      resource_id = "!:webservice:accounts"
      role = Role[role_id] or Role.create role_id: role_id
      Resource[resource_id] or Resource.create resource_id: resource_id, owner_id: role_id
    end

    def create id
      raise Exceptions::RecordExists.new("account", id) if Slosilo["authn:#{id}"]

      pkey = Slosilo::Key.new
      Slosilo["authn:#{id}"] = pkey
      admin_user = Role.create role_id: "#{id}:user:admin"
      admin_user.api_key
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

  def delete
    # Ensure the signing key exists
    slosilo_keystore.adapter.model.with_pk!("authn:#{id}")

    Role["#{id}:user:admin"].destroy
    Credentials.where(Sequel.lit("account(role_id)") => id).delete
    Secret.where(Sequel.lit("account(resource_id)") => id).delete
    slosilo_keystore.adapter.model["authn:#{id}"].destroy

    true
  end

  protected

  def slosilo_keystore
    Slosilo.send(:keystore)
  end
end
