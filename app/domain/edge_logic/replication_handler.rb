module ReplicationHandler
  include Secrets::RedisHandler

  def replicate_hosts(scope)
    results = []
    roles_with_creds = scope.eager(:credentials)
    hosts = Role.roles_with_annotations(roles_with_creds).all
    hosts.each do |host|
      host_to_return = {}
      host_to_return[:id] = host[:role_id]
      host_api_key = host.api_key
      if host_api_key.nil?
        host_to_return[:api_key] = ""
        host_to_return[:salt] = ""
      else
        salt = OpenSSL::Random.random_bytes(32)
        host_to_return[:api_key] = Base64.strict_encode64(hmac_api_key(host.api_key, salt))
        host_to_return[:salt] = Base64.strict_encode64(salt)
      end
      membership_proc = Proc.new do
        all_roles = host.all_roles
        if Rails.application.config.conjur_config.try(:conjur_edge_is_atlantis)
          # Filter out memberships to host, which probably indicates ownership rather than real membership
          all_roles = all_roles.where(~:role_id.like('%:host:%'))
        end
        all_roles.all.select { |h| h[:role_id] != (host[:role_id]) }
      end
      host_to_return[:memberships] = Rails.application.config.conjur_config.try(:conjur_edge_is_atlantis) ?
                                       get_role_membership(host[:role_id], &membership_proc) : membership_proc.call
      host_to_return[:annotations] = host[:annotations] == "[null]" ? [] : JSON.parse(host[:annotations])
      results << host_to_return
    end
    results
  end

  def replicate_secrets(limit, offset, options, accepts_base64, selective_enabled)
    variables = build_variables_map(limit, offset, options, selective_enabled)
    construct_variable(variables, accepts_base64, selective_enabled)
  end

  def replicate_single_secret(id, accepts_base64, selective_enabled)
    # limit = 1 and offset = 0 are used to get the latest version of the secret
    # If the secret has multiple versions, the latest version is returned
    limit = 1
    offset = 0
    variables = build_variables_map(limit, offset, nil, selective_enabled, id: id)
    construct_variable(variables, accepts_base64, selective_enabled)
  end

  private

  def construct_variable(variables, accepts_base64, selective_enabled)
    results = []
    failed = []

    variables.each do |id, variable|
      variable_to_return = {}
      variable_to_return[:id] = id
      variable_to_return[:owner] = variable[:owner_id]
      variable_to_return[:permissions] = get_permissions(id, variable, selective_enabled)
      secret_value = Slosilo::EncryptedAttributes.decrypt(variable[:value], aad: id)
      variable_to_return[:value] = accepts_base64 ? Base64.strict_encode64(secret_value) : secret_value
      variable_to_return[:version] = variable[:version]
      variable_to_return[:versions] = []
      value = {
        "version": variable_to_return[:version],
        "value": variable_to_return[:value]
      }
      variable_to_return[:versions] << value
      begin
        JSON.generate(variable_to_return)
        results << variable_to_return
      rescue
        failed << { "id": id }
      end
    end
    [results, failed]
  end

  def build_variables_map(limit, offset, options, selective_enabled, id: nil)
    variable_id = id.nil? ? "'#{options[:account]}:variable:data/%'" : "'#{id}'"  
    variables = {}
    if selective_enabled == "true"
      query_string = "SELECT * from allowed_secrets_per_role('#{current_user.id}', #{variable_id}, #{limit}, #{offset})"
    else
      query_string = "SELECT * FROM secrets JOIN (SELECT resource_id, owner_id FROM resources WHERE (resource_id LIKE #{variable_id}) ORDER BY resource_id LIMIT #{limit} OFFSET #{offset}) AS res ON (res.resource_id = secrets.resource_id)"
    end

    Sequel::Model.db.fetch(query_string) do |row|
      if variables.key?(row[:resource_id])
        if row[:version] > variables[row[:resource_id]][:version]
          variables[row[:resource_id]] = row
        end
      else
        variables[row[:resource_id]] = row
      end
    end
    variables
  end

  def get_permissions(id,variable,selective_enabled)
    permissions = []
    if selective_enabled == "true"
      Sequel::Model.db.fetch("SELECT * from permissions where resource_id='" + variable[:resource_id] + "' AND privilege = 'execute'") do |row|
        permission = {}
        permission[:privilege] = row[:privilege]
        permission[:resource] = row[:resource_id]
        permission[:role] = row[:role_id]
        permission[:policy] = row[:policy_id]
        permissions.append(permission)
      end
    else
      Permission.where(resource_id:id, privilege:'execute').each do |row|
        permission = {}
        permission[:privilege] = row[:privilege]
        permission[:resource] = row[:resource_id]
        permission[:role] = row[:role_id]
        permission[:policy] = row[:policy_id]
        permissions.append(permission)
      end
    end
    return permissions
  end
end
