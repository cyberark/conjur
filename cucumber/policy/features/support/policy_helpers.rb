# frozen_string_literal: true

module FullId
  def make_full_id(id, account: "cucumber")
    tokens  = id.split(":", 3)
    prepend = tokens.size == 2 ? [account] : []
    (prepend + tokens).join(':')
  end
end

# Utility methods for loading, replacing, etc of policies
#
module PolicyHelpers
  require 'cucumber/policy/features/support/client'
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

  def load_root_policy(policy)
    policy_helper('root').load_policy(policy)
  end

  def update_root_policy(policy)
    policy_helper('root').update_policy(policy)
  end

  def extend_root_policy(policy)
    policy_helper('root').extend_policy(policy)
  end

  def load_policy(id, policy)
    policy_helper(id).load_policy(policy)
  end

  def update_policy(id, policy)
    policy_helper(id).update_policy(policy)
  end

  def extend_policy(id, policy)
    policy_helper(id).extend_policy(policy)
  end

  def policy_helper(id)
    ClientHelpers::Policyhelpers::PolicyClient.new(id)
  end

  def json_result
    case @result
    when String
      JSON.parse(@result)
    when Hash
      @result
    end
  end

  def make_full_id(*tokens)
    super(tokens.join(":"))
  end

  def rest_client(root, kind, id)
    ClientHelpers::Client.new(root, kind, id)
  end

  def login_as_role(login, api_key = nil)
    client = rest_client("authn","login","any")
    api_key = client.admin_api_key if login == "admin"
    unless api_key
      role = if login.index('/')
        login.split('/', 2).join(":")
      else
        [ "user", login ].join(":")
      end
      api_key = client.create_api_key(role)
    end
    if login == "admin"
      @token = client.admin_token
    else
      @token = client.get_token(login, api_key)
    end
  end
end

World(PolicyHelpers)
