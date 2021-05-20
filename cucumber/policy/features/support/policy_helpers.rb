# frozen_string_literal: true

module FullId
  def make_full_id id, account: "cucumber"
    tokens  = id.split(":", 3)
    prepend = tokens.size == 2 ? [account] : []
    (prepend + tokens).join(':')
  end
end

# Utility methods for loading, replacing, etc of policies
#
module PolicyHelpers
  include FullId

  attr_reader :result

  # invoke accepts an optional HTTP status code as input
  # and checks that the result matches that code
  def invoke status: nil, &block
    begin
      @result = yield
      # raise "Expected invocation to be denied" if status && status != 200

      @result.tap do |result|
        puts(result) if @echo
      end
    rescue RestClient::Exception => e
      expect(e.http_code).to eq(status) if status
      @result = e.response.body
    end
  end

  def load_root_policy policy
    resource('root').put(policy, :Authorization => create_token_header())
  end

  def update_root_policy policy
     resource('root').patch(policy, :Authorization => create_token_header())
  end

  def extend_root_policy policy
    resource('root').post(policy, :Authorization => create_token_header())
  end

  def load_policy id, policy
    resource(id).put(policy, :Authorization => create_token_header())
  end

  def update_policy id, policy
    resource(id).patch(policy, :Authorization => create_token_header())
  end

  def extend_policy id, policy
    resource(id).post(policy, :Authorization => create_token_header())
  end

  def resource id
    RestClient::Resource.new('http://localhost:3000/policies/cucumber/policy/' + id)
  end

  # resource = resource('root')
  # res = resource.put(policy)
  # return res

  def make_full_id *tokens
    super(tokens.join(":"))
  end

  def json_result
    case @result
    when String
      JSON.parse(@result)
    when Hash
      @result
    end
  end

  def admin_api_key
    resource = RestClient::Resource.new 'http://localhost:3000/authn/cucumber/login' ,'admin', admin_password
    resource.get
  end

  def get_login_token login, key
    RestClient.post('http://localhost:3000/authn/cucumber/' + CGI.escape(login) + '/authenticate', key, 'Accept-Encoding': 'Base64')
  end

  def get_admin_token()
    admin_api_key = admin_api_key()
    RestClient.post('http://localhost:3000/authn/cucumber/admin/authenticate', admin_api_key, 'Accept-Encoding': 'Base64')
  end

  def create_token_header token=nil
    if token == nil
      token = get_admin_token()
    end
    token_header = 'Token token="' + token + '"'
  end

  def create_api_key role
    login_resource().put("", :Authorization => create_token_header(), params: {role: role})
  end

  def login_resource
      RestClient::Resource.new 'http://localhost:3000/authn/cucumber/api_key','admin', admin_password
  end

  def admin_password
    'SEcret12!!!!'
  end

  def login_as_role login, api_key = nil
    api_key = admin_api_key if login == "admin"
    unless api_key
      role = if login.index('/')
        login.split('/', 2).join(":")
      else
        [ "user", login ].join(":")
      end
      api_key = create_api_key(role)
    end
    @token = get_login_token(login, api_key)
  end
end
World(PolicyHelpers)
