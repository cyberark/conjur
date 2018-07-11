# frozen_string_literal: true

module RestHelpers
  
  USER_NAMES = %w(auto-larry auto-mike auto-norbert auto-otto)
  
  def headers
    @headers ||= {}
  end
  
  def post_json path, body, options = {}
    path = denormalize(path)
    body = denormalize(body)
    result = rest_resource(options)[path].post(body)
    set_result result
  end
  
  def put_json path, body = nil, options = {}
    path = denormalize(path)
    body = denormalize(body)
    result = rest_resource(options)[path].put(body)
    set_result result
  end

  def delete_json path, options = {}
    path = denormalize(path)
    result = rest_resource(options)[path].delete
    set_result result
  end

  def patch_json path, body = nil, options = {}
    path = denormalize(path)
    body = denormalize(body)
    result = rest_resource(options)[path].patch(body)
    set_result result
  end

  def get_json path, options = {}
    path = denormalize(path)
    result = rest_resource(options)[path].get
    set_result result
  end
  
  def set_result result
    @response_api_key = nil
    @status = result.code
    if result.headers[:content_type] =~ /^application\/json/
      @result = JSON.parse(result)
      @response_api_key = @result['api_key'] if @result.is_a?(Hash)
      if @result.respond_to?(:sort!)
        @result.sort! unless @result.first.is_a?(Hash)
      end
    else
      @result = result
    end
  end

  def set_token_result result
    unless result.blank?
      @result = JSON.parse(result)
    else
      @result = result
    end
  end

  def token_payload
    unless (payload = @result['payload'])
      raise "No 'payload' for token #{@result.inspect}"
    end
    JSON.parse Base64.decode64(payload)
  end

  def token_protected
    unless (prot = @result['protected'])
      raise "No 'protected' for token #{@result.inspect}"
    end
    JSON.parse Base64.decode64(prot)
  end

  # Write a command to the authn-local Unix socket.
  def authn_local_request command
    require 'socket'
    socket_file = "/run/authn-local/.socket"
    raise "Socket #{socket_file} does not exist" unless File.exists?(socket_file)
    UNIXSocket.open socket_file do |s|
      s.puts command
      s.read
    end
  end
  
  def authn_params
    raise "No selected user" unless @selected_user
    @authn_params = {
      id: @selected_user.login
    }
  end
  
  def last_json
    raise "No result captured!" unless @result
    JSON.pretty_generate(@result)
  end
  
  def users
    @users ||= {}
  end
  
  def lookup_user login, account = "cucumber"
    roleid = "#{account}:user:#{login}"
    existing = Role[roleid] rescue nil
    if existing
      Credentials.new(role: existing).save unless existing.credentials
      users[login] = existing
      existing
    else
      users[login]
    end.tap do |user|
      raise "No such user '#{login}'" unless user
    end
  end

  def foreign_admin_user account
    role_id = "#{account}:user:admin"
    Role[role_id] || Role.create(role_id: role_id)
  end
  
  def admin_user
    Role["cucumber:user:admin"]
  end
  
  # Create a regular user, owned by the admin user
  def create_user login, owner
    unless login
      login = USER_NAMES[@user_index]
      @user_index += 1
    end

    return if users[login]

    roleid = "cucumber:user:#{login}"
    Role.create(role_id: roleid).tap do |user|
      Credentials[role: user] or Credentials.new(role: user).save(raise_on_save_failure: true)
      Resource.create(resource_id: roleid, owner: owner)
      users[login] = user
    end
  end

  def current_user?
    !!@current_user
  end

  def current_user_api_key
    @current_user.api_key
  end
  
  def current_user_credentials
    headers = {}.tap do |h|
      token = Slosilo["authn:#{@current_user.account}"].signed_token @current_user.login
      h[:authorization] = "Token token=\"#{Base64.strict_encode64 token.to_json}\""
    end
    { headers: headers, username: @current_user.login }
  end

  def current_user_basic_auth password = nil
    password ||= @current_user.api_key
    { user: @current_user.login, password: password }
  end
  
  def token_auth_request
    RestClient::Resource.new(Conjur::Authn::API.host, current_user_credentials)
  end
  
  def basic_auth_request password = nil
    RestClient::Resource.new(Conjur::Authn::API.host, current_user_basic_auth(password))
  end
  
  def try_request can
    begin
      yield
    rescue RestClient::Exception
      puts $!
      @exception = $!
      @status = $!.http_code
      if can
        raise
      else
        set_result @exception.response
      end
    end
  end
  
  def account
    "cucumber"
  end

  def random_hex nbytes = 12
    @random ||= Random.new
    @random.bytes(nbytes).unpack('h*').first
  end
  
  protected

  def denormalize str
    return unless str
    return if str.is_a?(Hash)
    str = str.dup
    patterns = {}
    patterns["api_key"] = current_user_api_key if current_user?
    if @current_resource
      patterns["resource_id"] = @current_resource.identifier
      patterns["resource_kind"] = @current_resource.kind
    end
    users.each do |k,v|
      patterns["#{k}_api_key"] = v.credentials.api_key
    end
    patterns.each do |k,v|
      str.gsub! ":#{k}", v
      str.gsub! "@#{k}@", v
      str.gsub! CGI.escape(":#{k}"), CGI.escape(v)
      str.gsub! CGI.escape("@#{k}@"), CGI.escape(v)
    end
    str
  end

  def rest_resource options
    args = [ Conjur.configuration.appliance_url ]
    args << current_user_credentials if current_user?
    args << Hash.new if args.length == 1
    args.last[:headers] ||= {}
    args.last[:headers].merge(headers) if headers
    RestClient::Resource.new(*args).tap do |request|
      headers.each do |k,v|
        request.headers[k] = v
      end
      if options[:user] && options[:password]
        request.options[:user] = denormalize(options[:user])
        request.options[:password] = denormalize(options[:password])
      end
    end
  end
end

World(RestHelpers)
