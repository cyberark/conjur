module PossumWorld
  def params
    @params ||= {}
  end
  
  def namespace
    @namespace
  end
  
  def admin_user
    unless @admin_user
      # Create the admin user and grant it 'admin' role
      admin_login = user_login('admin')
              
      admin_user = Role.create(id: "cucumber:user:#{admin_login}")
      Credentials.new(role: admin_user).save(raise_on_save_failure: true)
      
      Role['cucumber:user:admin'].grant_to admin_user, admin_option: true
      
      @admin_user = admin_user
    end
    @admin_user
  end
  
  def normal_user
    unless @normal_user
      # Create a regular user, owned by the admin user
      normal_user = Role.create(id: "cucumber:user:#{user_login('alice')}")
      Credentials.new(role: normal_user).save(raise_on_save_failure: true)

      @normal_user = normal_user
    end
    @normal_user
  end
  
  def user_login login
    [ login, namespace.gsub('/', '-') ].join("@")
  end
  
  def current_user_credentials
    @current_user ? @current_user.api.credentials : @user.api.credentials
  end

  def current_user_basic_auth password = nil
    if @current_user
      { user: @current_user.login, password: 'password' }
    else
      password ||= @user.api_key
      { user: @user.login, password: password }
    end
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
    text.gsub "#{namespace}/", ""
  end  
end

World(PossumWorld)
