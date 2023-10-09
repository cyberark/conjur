# frozen_string_literal: true

require('net/http')
require('uri')

# Utility methods for making API requests
#
module RestHelpers

  def headers
    @headers ||= {}
  end

  def post_json path, body, options = {}
    path = denormalize(path)
    body = denormalize(body)
    result = rest_resource(options)[path].post(body)
    set_result(result)
  end

  def post_multipart_json path
    denormalized_path = denormalize(path)

    cleaned_path, parameters = strip_rest_params_from_path(denormalized_path)
    result = rest_resource({})[cleaned_path].post(parameters)
    set_result(result)
  end

  def put_json path, body = nil, options = {}
    path = denormalize(path)
    body = denormalize(body)
    result = rest_resource(options)[path].put(body)
    set_result(result)
  end

  def delete_json path, options = {}
    path = denormalize(path)
    result = rest_resource(options)[path].delete
    set_result(result)
  end

  def patch_json path, body = nil, options = {}
    path = denormalize(path)
    body = denormalize(body)
    result = rest_resource(options)[path].patch(body)
    set_result(result)
  end

  def get_json(path, options = {})
    path = denormalize(path)
    result = rest_resource(options)[path].get
    set_result(result)
  end

  # Since there is no way to remove the default Accept header from RestClient
  # we use Net:HTTP here. Otherwise we would not be able to simulate requests
  # that omit the Accept header in our tests.
  def get_json_no_accept_header(path, options = {})
    uri = URI(root_url + denormalize(path))
    headers = request_opts(options)[:headers]
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)

    request.delete('Accept')
    headers.each { |key, value| request[key] = value }

    if options[:user] && options[:password]
      request.basic_auth(options[:user], options[:password])
    end

    response = http.request(request)

    if response.content_type == 'application/json'
      @result = JSON.parse(response.body)
    else
      @result = response.body
    end
  end

  # TODO: Add proper fix for this with real refactor of test code
  #
  # NOTE: The way this works is tricky.  We are relying on a behavior of
  # RestClient, which will automatically add a Basic Auth header to your
  # request, if you've set the user and password fields on its Request object:
  #
  # See: https://github.com/rest-client/rest-client/blob/f450a0f086f1cd1049abbef2a2c66166a1a9ba71/spec/unit/request_spec.rb#L442
  #
  # However, it will only do this IF the request does not already have its
  # Authorization header set.  Because we wish to use this behavior to construct
  # our Basic Auth header, we explicitly delete the ":authorization" header.
  # Our own "rest_resource" method ensures that "user" and "password" are set
  # on the request.
  #
  def get_json_with_basic_auth(path, options = {})
    path = denormalize(path)
    resource = rest_resource(options)[path]
    # TODO: Add proper fix for this with real refactor of test code
    resource.options[:headers].delete(:authorization)
    result = resource.get
    set_result(result)
  end

  def strip_rest_params_from_path path
    uri = URI.parse(path)
    params = {}
    params = CGI.parse(uri.query) if uri.query

    # Stringified params keys have [] at the end so we clip those
    # They also turn all params into an array so we ensure that we don't send
    # garbage
    remapped_params = {}
    params.each do |key, val|
      if key.ends_with?("[]")
        remapped_params[key.chomp("[]")] = val
      else
        remapped_params[key.chomp("[]")] = val.first
      end
    end

    # Remove query params from our new uri
    uri.query=""
    new_path = uri.to_s

    [new_path, remapped_params]
  end

  def set_result result
    @response_api_key = nil
    @http_status = result.code

    @content_type = result.headers[:content_type]
    @content_encoding = result.headers[:content_encoding]
    if /^application\/json/.match?(@content_type)
      @result = JSON.parse(result)
      @response_api_key = @result['api_key'] if @result.is_a?(Hash)
      if @result.respond_to?(:sort!) && !@result.first.is_a?(Hash)
        @result.sort!
      end
    else
      @result = result
    end
  end

  def set_token_result result
    @result = if result.blank?
      result
    else
      JSON.parse(result)
    end
  end

  def token_payload
    unless (payload = @result['payload'])
      raise "No 'payload' for token #{@result.inspect}"
    end

    JSON.parse(Base64.decode64(payload))
  end

  def token_protected
    unless (prot = @result['protected'])
      raise "No 'protected' for token #{@result.inspect}"
    end

    JSON.parse(Base64.decode64(prot))
  end

  # Write a command to the authn-local Unix socket.
  def authn_local_request command
    require 'socket'
    socket_file = ENV['AUTHN_LOCAL_SOCKET']
    raise "Socket #{socket_file} does not exist" unless File.exist?(socket_file)

    UNIXSocket.open(socket_file) do |sock|
      sock.puts(command)
      sock.read
    end
  end

  def authn_request(url:, api_key:, encoding:, can:)
    headers["Accept-Encoding"] = encoding
    try_request(can) do
      post_json(url, api_key)
    end
  end

  def authn_params
    raise 'No selected user' unless @selected_user

    @authn_params = {
      id: @selected_user.login
    }
  end

  def last_json
    raise 'No result captured!' unless @result

    JSON.pretty_generate(@result)
  end

  def roles
    @roles ||= {}
  end

  def lookup_host login, account = 'cucumber'
    roleid = "#{account}:host:#{login}"
    lookup_role(roleid)
  end

  def lookup_user login, account = 'cucumber'
    roleid = "#{account}:user:#{login}"
    lookup_role(roleid)
  end

  def lookup_group login, account = 'cucumber'
    roleid = "#{account}:group:#{login}"
    lookup_role(roleid)
  end

  def lookup_role roleid
    existing = begin
      Role[roleid]
    rescue
      nil
    end
    if existing
      Credentials.new(role: existing).save unless existing.credentials
      roles[roleid] = existing
      existing
    else
      roles[roleid]
    end.tap do |role|
      raise "No such role '#{roleid}'" unless role
    end
  end

  def foreign_admin_user account
    role_id = "#{account}:user:admin"
    Role[role_id] || Role.create(role_id: role_id)
  end

  def admin_user
    Role['cucumber:user:admin']
  end

  # Create a regular user, owned by the admin user
  def create_user login, owner
    roleid = "cucumber:user:#{login}"
    create_role(roleid, owner)
  end

  # Create a regular host, owned by the admin user
  def create_host login, owner, api_key_annotation=true
    roleid = "cucumber:host:#{login}"
    create_role(roleid, owner, api_key_annotation)
  end

  def create_role roleid, owner, api_key_annotation=false
    return if roles[roleid]

    resource = Resource.create(resource_id: roleid, owner: owner)
    # If needed add the annotation to create api key
    puts "roleid:#{roleid}; api_key:#{api_key_annotation}"
    if api_key_annotation
      puts "adding annotation"
      resource.annotations <<
        Annotation.create(resource: resource,
                          name: "authn/api-key",
                          value: "true")
    end

    Role.create(role_id: roleid).tap do |role|
      Credentials[role: role] || Credentials.new(role: role).save(raise_on_save_failure: true)
      roles[roleid] = role
    end
  end

  # TODO: This isn't a RestHelper
  #   We probably want an object encapsulating DB interactions like a
  #   UserRepo or db.User... TBD
  def user_exists? login
    roleid = "cucumber:user:#{login}"
    Role[role_id: roleid]
  end

  def host_exists? login
    roleid = "cucumber:host:#{login}"
    Role[role_id: roleid]
  end

  def current_user?
    !!@current_user
  end

  def current_user_api_key
    @current_user.api_key
  end

  def current_user_credentials
    username = @current_user.login
    # Configure Slosilo to produce valid access tokens
    slosilo_user = Slosilo["authn:#{@current_user.account}:user:current"] ||= Slosilo::Key.new
    # NOTE: 'iat' (issueat) is expected to be autogenerated
    token = slosilo_user.issue_jwt(sub: username)
    user_credentials(username, token)
  end

  def user_credentials(username, token)
    token_authorization = "Token token=\"#{Base64.strict_encode64(token.to_json)}\""
    headers = { authorization: token_authorization }
    { headers: headers, username: username }
  end

  def current_user_basic_auth(password = nil)
    password ||= @current_user.api_key
    { user: @current_user.login, password: password }
  end

  def token_auth_request
    RestClient::Resource.new(Conjur::Authn::API.host, current_user_credentials)
  end

  def basic_auth_request(password = nil)
    RestClient::Resource.new(
      Conjur::Authn::API.host,
      current_user_basic_auth(password)
    )
  end

  def full_conjur_url(path)
    URI.parse(Conjur.configuration.appliance_url + path)
  end

  def try_request can
    yield
  rescue RestClient::Exception
    puts($ERROR_INFO)
    @exception = $ERROR_INFO
    @http_status = $ERROR_INFO.http_code
    raise if can

    set_result(@exception.response)  
  end

  def account
    'cucumber'
  end

  def random_hex nbytes = 12
    @random ||= Random.new
    @random.bytes(nbytes).unpack1('h*')
  end

  protected

  def api_key_for_role_id(role_id)
    roles[role_id].credentials.api_key
  end

  def denormalize str
    return unless str
    return if str.is_a?(Hash)

    str = str.dup
    patterns = {}
    patterns['api_key'] = current_user_api_key if current_user?
    if @current_resource
      patterns['resource_id'] = @current_resource.identifier
      patterns['resource_kind'] = @current_resource.kind
    end
    roles.each do |key, val|
      patterns["#{key}_api_key"] = val.credentials.api_key
    end
    patterns.each do |key, val|
      if val.nil?
        val = ""
      end
      str.gsub!(":#{key}", val)
      str.gsub!("@#{key}@", val)
      str.gsub!(CGI.escape(":#{key}"), CGI.escape(val))
      str.gsub!(CGI.escape("@#{key}@"), CGI.escape(val))
    end
    str
  end

  def root_url
    Conjur.configuration.appliance_url
  end

  def request_opts(options)
    creds =
      if options[:token]
        user_credentials(options[:token].username, options[:token].token)
      elsif current_user?
        current_user_credentials
      else
        {}
      end

    creds[:headers] ||= {}
    creds[:headers].merge!(headers)
    creds
  end

  def rest_resource(options)
    RestClient::Resource.new(root_url, request_opts(options)).tap do |request|
      if options[:user] && options[:password]
        request.options[:user] = denormalize(options[:user])
        request.options[:password] = denormalize(options[:password])
      end
    end
  end
end

World(RestHelpers)
