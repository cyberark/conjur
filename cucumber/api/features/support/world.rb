module PossumWorld
  
  USER_NAMES = %w(auto-larry auto-mike auto-norbert auto-otto)
  
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
    users[login] or raise "No such user '#{login}'"
  end
  
  def admin_user
    unless @admin_user
      # Create the admin user and grant it 'admin' role
      admin_login = user_login('admin')
              
      admin_user = Role.create(role_id: "cucumber:user:#{admin_login}")
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
  
  def current_user_credentials
    @current_user.api.credentials
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
end

World(PossumWorld)
