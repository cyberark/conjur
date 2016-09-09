module PossumWorld
  
  USER_NAMES = %w(auto-larry auto-mike auto-norbert auto-otto)
  
  def post_json path, body, options = {}
    denormalize!(path)
    denormalize!(body)
    result = rest_resource(options)[path].post(body)
    set_result result
  end
  
  def put_json path, body = nil, options = {}
    denormalize!(path)
    denormalize!(body)
    result = rest_resource(options)[path].put(body)
    set_result result
  end

  def get_json path, options = {}
    denormalize!(path)
    result = rest_resource(options)[path].get
    set_result result
  end
  
  def set_result result
    if result.headers[:content_type] =~ /^application\/json/
      @result = JSON.parse(result)
      if @result.respond_to?(:sort!)
        @result.sort! unless @result.first.is_a?(Hash)
      end
    else
      @result = result
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
    strip_namespace(JSON.pretty_generate(@result))
  end
  
  def namespace
    @namespace
  end
  
  def user_namespace
    namespace.gsub('/', '-')
  end
  
  def users
    @users ||= {}
  end
  
  def lookup_user login
    existing = Role["cucumber:user:#{login}"] rescue nil
    if existing
      Credentials.new(role: existing).save unless existing.credentials
      users[existing.identifier] = existing
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
    unless @admin_user
      # Create the admin user and grant it 'admin' role
      admin_login = user_login('admin')
              
      admin_user = Role.create(role_id: "cucumber:user:#{admin_login}")
      Role['cucumber:user:admin'].grant_to admin_user
      Credentials.new(role: admin_user).save(raise_on_save_failure: true)
      
      @admin_user = admin_user
    end
    @admin_user
  end
  
  # Create a regular user, owned by the admin user
  def create_user login = nil
    unless login
      login = USER_NAMES[@user_index]
      @user_index += 1
    end

    return if users[login]

    roleid = "cucumber:user:#{user_login(login)}"
    Role.create(role_id: roleid).tap do |user|
      user.grant_to admin_user, admin_option: true
      Credentials.new(role: user).save(raise_on_save_failure: true)
      Resource.create(resource_id: roleid, owner: admin_user)
      users[login] = user
    end
  end
  
  def user_login login
    [ login, user_namespace ].join("@")
  end
  
  def current_user?
    !!@current_user
  end

  def current_user_api_key
    @current_user.api_key
  end
  
  def current_user_credentials
    headers = {}.tap do |h|
      token = Slosilo["authn:cucumber"].signed_token @current_user.login
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
      @exception = $!
      @status = $!.http_code
      raise if can
    end
  end
  
  def account
    "cucumber"
  end
  
  def inject_namespace text
    text.gsub "@namespace@", namespace
  end
  
  def strip_namespace text
    return "" if text.nil?
    text.gsub("#{namespace}/", "").gsub("@#{user_namespace}", "")
  end  
    
  def denormalize str
    str.dup.tap do |str|
      denormalize! str
    end
  end
  
  def denormalize! path
    return unless path
    return if path.is_a?(Hash)
    patterns = {
      "account" => account,
      "user_namespace" => user_namespace,
      "namespace" => namespace
    }
    patterns["api_key"] = current_user_api_key if current_user?
    if @current_resource
      patterns["resource_id"] = @current_resource.identifier
      patterns["resource_kind"] = @current_resource.kind
    end
    users.each do |k,v|
      patterns["#{k}_api_key"] = v.credentials.api_key
    end
    patterns.each do |k,v|
      path.gsub! ":#{k}", v
      path.gsub! "@#{k}@", v
      path.gsub! CGI.escape(":#{k}"), CGI.escape(v)
      path.gsub! CGI.escape("@#{k}@"), CGI.escape(v)
    end
  end
  
  def random_hex nbytes = 12
    @random ||= Random.new
    @random.bytes(nbytes).unpack('h*').first
  end

  protected
  
  def rest_resource options
    args = [ Conjur.configuration.appliance_url ]
    args << current_user_credentials if current_user?
    RestClient::Resource.new(*args).tap do |request|
      if options[:user] && options[:password]
        request.options[:user] = denormalize(options[:user])
        request.options[:password] = denormalize(options[:password])
      end
    end
  end
end

World(PossumWorld)
