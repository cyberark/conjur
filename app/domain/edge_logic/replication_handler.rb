module ReplicationHandler

  def replicate_hosts(scope)
    results = []
    roles_with_creds = scope.eager(:credentials)
    hosts = Role.roles_with_annotations(roles_with_creds).all
    hosts.each do |host|
      hostToReturn = {}
      hostToReturn[:id] = host[:role_id]
      salt = OpenSSL::Random.random_bytes(32)
      hostToReturn[:api_key] = Base64.strict_encode64(hmac_api_key(host.api_key, salt))
      hostToReturn[:salt] = Base64.strict_encode64(salt)
      hostToReturn[:memberships] = host.all_roles.all.select { |h| h[:role_id] != (host[:role_id]) }
      hostToReturn[:annotations] = host[:annotations] == "[null]" ? [] : JSON.parse(host[:annotations])
      results << hostToReturn
    end
    results
  end

  def authorize(privilege, resource)
    return current_user.allowed_to?(privilege, resource)
  end

  def replicate_secrets(limit, offset, options, accepts_base64)
    results = []
    failed = []

    implementation_version = 3
    if (implementation_version == 3)

      query_str = "SELECT * from allowed_secrets_per_role1('" + current_user.id + "','conjur:variable:data/%', " + limit.to_s + ", " + offset.to_s + ")"

      Rails.logger.info("+++++++++++ replicate_secrets 1 query_str = #{query_str}")
      Sequel::Model.db.fetch(query_str) do |variable|
        Rails.logger.info("+++++++++++ replicate_secrets 1.1 variable=#{variable}")
        variableToReturn = {}
        variableToReturn[:id] = variable[:resource_id]
        variableToReturn[:owner] = variable[:owner_id]
        variableToReturn[:permissions] = []
        Sequel::Model.db.fetch("SELECT * from permissions where resource_id='" + variable[:resource_id] + "' AND privilege = 'execute'") do |row|
          permission = {}
          permission[:privilege] = row[:privilege]
          permission[:resource] = row[:resource_id]
          permission[:role] = row[:role_id]
          permission[:policy] = row[:policy_id]
          variableToReturn[:permissions].append(permission)
        end
        secret_value = Slosilo::EncryptedAttributes.decrypt(variable[:value], aad: variable[:resource_id])
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
      Rails.logger.info("+++++++++++ replicate_secrets 1.2")

    else
    Rails.logger.info("+++++++++++ replicate_secrets 1.3")


    replicatorCachePath = ENV['TENANT_ID'] + "/secrets/" + "replication/replicationInCache/" + offset + "/" + limit
    replicationInCache = $redis.get(replicatorCachePath)
    if (replicationInCache.nil?)
      Rails.logger.info("+++++++++++ replicate_secrets 2 offset = #{offset}, limit = #{limit}, replicatorCachePath=#{replicatorCachePath}")
      variables = build_variables_map(limit, offset, options)
      variables.each do |id, variable|
        Rails.logger.info("+++++++++++ replicate_secrets 3 id = #{id}")
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
        #Rails.logger.info("+++++++++++ replicate_secrets 4 value = #{value}")
        variableToReturn[:versions] << value
        JSON.generate(variableToReturn)
        Rails.logger.info("+++++++++++ replicate_secrets 4.1  id = #{id} variableToReturn = #{variableToReturn}")
        $redis.set(ENV['TENANT_ID'] + "/secrets/" + "replication/" + id, variableToReturn)
      end
      $redis.set(replicatorCachePath, "1")
    end
    Rails.logger.info("+++++++++++ replicate_secrets 4.1.1")

    hostPermisionsCachePath = ENV['TENANT_ID'] + "/secrets/" + "replication/hostPermisionsInCache1/" + current_user.id + "/" + offset + "/" + limit
    hostPermisionsInCache = $redis.get(hostPermisionsCachePath)
    if (hostPermisionsInCache.nil?)

      query_str = "SELECT * from permitted_resources_per_role('" + current_user.id + "','conjur:variable:data/%', " + limit.to_s + ", " + offset.to_s + ")"

      Rails.logger.info("+++++++++++ replicate_secrets 5 query_str = #{query_str}")
      hostPermisionsInCache = ""
      Sequel::Model.db.fetch(query_str) do |row|
        hostPermisionsInCache.concat(row[:resource_id] + ",")
      end
      $redis.set(hostPermisionsCachePath, hostPermisionsInCache)

    end
    resources_array = hostPermisionsInCache.split(",")

    Rails.logger.info("+++++++++++ replicate_secrets 6 resources_array = #{resources_array}")

    #resourceKeys = $redis.keys(ENV['TENANT_ID'] + "/secrets/" + "replication/*")
    #count=0
    resources_array.each do |resource_id|
    #resourceKeys.each do |redis_id|
        #Rails.logger.info("+++++++++++ replicate_secrets 6 id = #{id}")
        resourceObj = Resource.new()
        ##OFIRA resourceObj.resource_id = row[:resource_id]
        #resourceObj.resource_id = redis_id.sub(ENV['TENANT_ID'] + "/secrets/" + "replication/", "")
        resourceObj.resource_id = resource_id

        #if (authorize(:execute, resourceObj))
          ##OFIRA redis_id = ENV['TENANT_ID'] + "/secrets/" + "replication/" + row[:resource_id]
          redis_id = ENV['TENANT_ID'] + "/secrets/" + "replication/" + resourceObj.resource_id
          variableToReturn = $redis.get(redis_id)
          Rails.logger.info("+++++++++++ replicate_secrets 7 resourceObj.resource_id = #{resourceObj.resource_id}, variableToReturn = #{variableToReturn}")
          begin
            JSON.generate(variableToReturn)
            results << variableToReturn
          rescue => e
            failed << { "id": id }
          end
        #end
        #Rails.logger.info("+++++++++++ replicate_secrets 7.1 count = #{count}")
        #break if count > 400
        #count += 1
        #Rails.logger.info("+++++++++++ replicate_secrets 7.2 count = #{count}, limit = 400")
        #if (count > 400)
        #  Rails.logger.info("+++++++++++ replicate_secrets 7.3 count = #{count}, limit = 400")
          #break
        #end
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
