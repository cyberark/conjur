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

  def json_result
    case @result
    when String
      JSON.parse(@result)
    when Hash
      @result
    end
  end

  # Executes a RestClient network call.  Rescues any error and and returns an
  # object with the same interface as a successful response. This uniform
  # interface makes it easier to write expectations.
  def api_response
    rest_client_resp = yield
    SimpleDelegator.new(rest_client_resp).tap do |resp|
      def resp.body
        # If it can't be parsed as JSON, return it unchanged.  The :content_type
        # header is not reliable.
        JSON.parse(super)
      rescue
        super
      end
    end
  rescue RestClient::Exception => e
    Object.new.tap do |obj|
      obj.instance_eval do
        @err = e

        def code
          @err.http_code
        end

        def body
          JSON.parse(@err.response.body)
        end
      end
    end
  end

  def make_full_id(*tokens)
    super(tokens.join(":"))
  end

end

World(PolicyHelpers)
