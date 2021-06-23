require 'delegate'
require 'json'
require 'rest-client'

class Client
  # RestClientWrapper provides a uniform interface to RestClient::Resource.
  # Instead of raising a RestClient::Error when requests fail, it returns a
  # result object with the same interface as a successful result. You can
  # check for an error using `code`, which returns the http status code.  You
  # can use `body` to get body of a failed request.
  #
  # False positive. @err is guaranteed to be set.
  # :reek:InstanceVariableAssumption
  class RestClientWrapper
    def initialize(rest_client)
      @rest_client = rest_client
    end

    def get(headers = {}, &block)
      result { @rest_client.get(headers, &block) }
    end

    # We're just matching the API of RestClient.
    # :reek:DataClump
    def post(payload, headers = {}, &block)
      result { @rest_client.post(payload, headers, &block) }
    end

    # :reek:DataClump
    def put(payload, headers = {}, &block)
      result { @rest_client.put(payload, headers, &block) }
    end

    # :reek:DataClump
    def patch(payload, headers = {}, &block)
      result { @rest_client.patch(payload, headers, &block) }
    end

    private

    def result(&_blk)
      raw_resp = yield
      SimpleDelegator.new(raw_resp).tap do |resp|
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
  end
end