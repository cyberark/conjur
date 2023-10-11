module ReplicationHandler

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
      host_to_return[:memberships] = host.all_roles.all.select { |h| h[:role_id] != (host[:role_id]) }
      host_to_return[:annotations] = host[:annotations] == "[null]" ? [] : JSON.parse(host[:annotations])
      results << host_to_return
    end
    results
  end

  def replicate_secrets(limit, offset, options, accepts_base64)
    results = []
    failed = []

    variables = build_variables_map(limit, offset, options)

    variables.each do |id, variable|
      variableToReturn = {}
      variableToReturn[:id] = id
      variableToReturn[:owner] = variable[:owner_id]
      variableToReturn[:permissions] = []
      Sequel::Model.db.fetch("SELECT * from permissions where resource_id='" + id + "' AND privilege = 'execute'") do |row|
        permission = {}
        permission[:privilege] = row[:privilege]
        permission[:resource] = row[:resource_id]
        permission[:role] = row[:role_id]
        permission[:policy] = row[:policy_id]
        variableToReturn[:permissions].append(permission)
      end
      secret_value = Slosilo::EncryptedAttributes.decrypt(variable[:value], aad: id)
      variableToReturn[:value] = accepts_base64 ? Base64.strict_encode64(secret_value) : secret_value
      variableToReturn[:version] = variable[:version]
      variableToReturn[:versions] = []
      value = {
        "version": variableToReturn[:version],
        "value": variableToReturn[:value]
      }
      variableToReturn[:versions] << value
      begin
        JSON.generate(variableToReturn)
        results << variableToReturn
      rescue => e
        failed << { "id": id }
      end
    end

    [results, failed]
  end

  private

  def build_variables_map(limit, offset, options)
    variables = {}

    Sequel::Model.db.fetch("SELECT * FROM secrets JOIN (SELECT resource_id, owner_id FROM resources WHERE (resource_id LIKE '" + options[:account] + ":variable:data/%') ORDER BY resource_id LIMIT " + limit.to_s + " OFFSET " + offset.to_s + ") AS res ON (res.resource_id = secrets.resource_id)") do |row|
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
end