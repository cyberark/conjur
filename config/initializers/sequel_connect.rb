class Sequel::Database

  # This code is copied from sequel/database/connecting.rb method server_opts, it was the only hack to support new thread with new connection, the old hack caused infinite loop.
  # We will have to notice changes in Sequel gem that affect his method from now.
  def server_opts(server)
    opts = if @opts[:servers] and server_options = @opts[:servers][server]
             case server_options
             when Hash
               @opts.merge(server_options)
             when Proc
               @opts.merge(server_options.call(self))
             else
               raise Error, 'Server opts should be a hash or proc'
             end
           elsif server.is_a?(Hash)
             @opts.merge(server)
           else
             @opts.dup
           end
    opts.delete(:servers)
    if should_update_password
      # In Case of running on cloud, update the password on each connect request.
      # The reason is that IAM password is valid only for 15 min, so we refresh the password on each new connection
      password = get_current_iam_password(opts)
      opts = opts.merge({ :password => password })
    end
    opts
  rescue => e
    raise e
  end

  private

  def get_current_iam_password(opts)
    credentials = assume_role
    token = generate_token(credentials, opts[:user])
    generate_db_url(token, opts[:user], opts[:search_path], opts[:host])
    token
  end

  def assume_role
    tenant_region = get_tenant_region
    Aws.config.update({ log_level: :debug, region: tenant_region })
    tenant_id = get_tenant_id
    sts_client = Aws::STS::Client.new
    tags = [
      { key: 'tenant_id', value: "#{tenant_id}" }, { key: "db_id", value: ENV["CONJUR_DB_RDS_ID"] }
    ]
    resp = sts_client.assume_role({ role_arn: get_role_arn, role_session_name: "role_session_name", tags: tags })
    # Extract temporary credentials
    resp.credentials
  end

  # This function generates temporary token for the db, It uses the sts credentials of the assumed role.
  def generate_token(credentials, user)
    hostname_port = get_rds_hostname_port
    username = user
    tenant_region = get_tenant_region
    # Set up AuthTokenGenerator with the assumed role's temporary credentials
    auth_token_generator = Aws::RDS::AuthTokenGenerator.new(
      region: tenant_region,
      credentials: Aws::Credentials.new(credentials.access_key_id, credentials.secret_access_key, credentials.session_token)
    )
    auth_token_generator.auth_token(endpoint: hostname_port, user_name: username, region: tenant_region)
  end

  def generate_db_url(token, username, search_path, rds_hostname2)
    password = CGI.escape(token)
    ENV['DATABASE_URL'] = "postgres://#{username}:#{password}@#{rds_hostname2}/postgres?search_path=#{search_path}"
  end

  def get_tenant_id
    ENV['TENANT_ID'].gsub('-', '')
  end

  def get_tenant_region
    ENV['TENANT_REGION']
  end

  def get_role_arn
    ENV['CONJUR_DB_CONNECTION_ROLE_ARN']
  end

  def get_rds_hostname_port
    ENV["DATABASE_HOSTNAME"]
  end

  def should_update_password
    ENV['RAILS_ENV'] == 'cloud'
  end
end