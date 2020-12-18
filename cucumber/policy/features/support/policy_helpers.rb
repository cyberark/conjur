# frozen_string_literal: true

require 'delegate'

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

  def load_root_policy policy
    conjur_api.load_policy "root", policy, method: Conjur::API::POLICY_METHOD_PUT
  end

  def update_root_policy policy
    conjur_api.load_policy "root", policy, method: Conjur::API::POLICY_METHOD_PATCH
  end

  def extend_root_policy policy
    conjur_api.load_policy "root", policy, method: Conjur::API::POLICY_METHOD_POST
  end

  def load_policy id, policy, context: nil
    conjur_api.load_policy id, policy, method: Conjur::API::POLICY_METHOD_PUT, context: context
  end

  def update_policy id, policy
    conjur_api.load_policy id, policy, method: Conjur::API::POLICY_METHOD_PATCH
  end

  def extend_policy id, policy
    conjur_api.load_policy id, policy, method: Conjur::API::POLICY_METHOD_POST
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
    when Hash
      @result
    end
  end

  def make_full_id(*tokens)
    super(tokens.join(":"))
  end

end

World(PolicyHelpers)
