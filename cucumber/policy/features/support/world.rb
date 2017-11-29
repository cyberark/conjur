module FullId
  def make_full_id id, account: Conjur.configuration.account
    tokens = id.split(":", 3)
    case tokens.length
    when 2
      tokens.unshift account
    when 3
      # pass
    else
      raise "Expected at least two tokens in #{id}"
    end
    tokens.join(":")
  end
end

module PossumWorld
  include FullId

  attr_reader :result

  def invoke status: :ok, &block
    begin
      @result = yield
      raise "Expected invocation to be denied" unless status == :ok
      @result.tap do |result|
        puts result if @echo
      end
    rescue RestClient::Exception => e
      expect(e.http_code).to eq(status) if status.is_a? Integer
      @result = e.response.body
    end
  end

  def load_root_policy policy
    conjur_api.load_policy "root", policy, method: Conjur::API::POLICY_METHOD_PUT
  end

  def update_root_policy policy
    conjur_api.load_policy "root", policy, method: Conjur::API::POLICY_METHOD_PATCH
  end

  def extend_root_policy policy
    conjur_api.load_policy "root", policy, method: Conjur::API::POLICY_METHOD_POST
  end

  def load_policy id, policy
    conjur_api.load_policy id, policy, method: Conjur::API::POLICY_METHOD_PUT
  end

  def update_policy id, policy
    conjur_api.load_policy id, policy, method: Conjur::API::POLICY_METHOD_PATCH
  end

  def extend_policy id, policy
    conjur_api.load_policy id, policy, method: Conjur::API::POLICY_METHOD_POST
  end

  def load_policy_from_file policy_file
    dir = File.expand_path('policy', File.dirname(__FILE__))
    Dir.chdir dir do
      open(policy_file).read
    end
  end

  def make_full_id *tokens
    super tokens.join(":")
  end

  def conjur_api
    login_as_role 'admin', admin_api_key unless @conjur_api
    @conjur_api
  end

  def json_result
    case @result
    when String
      JSON.parse(@result)
    when Conjur::PolicyLoadResult
      JSON.parse(@result.to_json)
    end
  end

  def admin_api_key
    @admin_api_key ||= Conjur::API.login 'admin', admin_password
  end

  def admin_password
    ENV['CONJUR_AUTHN_PASSWORD'] || 'admin'
  end

  def login_as_role login, api_key = nil
    api_key = admin_api_key if login == "admin"
    unless api_key
      role = if login.index('/')
        login.split('/', 2).join(":")
      else
        [ "user", login ].join(":")
      end
      api_key = Conjur::API.new_from_key('admin', admin_api_key).role(make_full_id(role)).rotate_api_key
    end
    @conjur_api = Conjur::API.new_from_key login, api_key
  end
end

World(PossumWorld)
