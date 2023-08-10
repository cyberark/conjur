# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

require_relative('ephemeral_engine_client')

class ConjurEphemeralEngineClient
  include EphemeralEngineClient

  def initialize(logger:, request_id:, http_client: nil)
    if http_client
      @client = http_client
    else
      @client = Net::HTTP.new("http://127.0.0.1")
      @client.use_ssl = false  # Service mesh takes care of the TLS communication
    end
    @logger = logger
    @request_id = request_id
  end

  def get_ephemeral_secret(type, method, role_id, platform_data, variable_data)
    request_body = {
      type: type,
      method: method,
      role: role_id,
      platform: hash_keys_to_camel_case(platform_data),
      secret: hash_keys_to_camel_case(variable_data)
    }

    # Create the POST request
    secret_request = Net::HTTP::Post.new("/secrets")
    secret_request.body = request_body.as_json

    # Add headers
    secret_request.add_field('Content-Type', 'application/json')
    secret_request.add_field('X-Request-ID', @request_id)
    secret_request.add_field('X-Tenant-ID', tenant_id)

    # Send the request and get the response
    @logger.info(LogMessages::Secrets::EphemeralSecretRemoteRequest.new(@request_id))
    begin
      response = @client.request(secret_request)
    rescue => e
      raise ApplicationController::InternalServerError, e.message
    end
    @logger.info(LogMessages::Secrets::EphemeralSecretRemoteResponse.new(@request_id, response.code))
    response_body = JSON.parse(response.body)

    case response.code.to_i
    when 200..299
      return JSON.parse(response.body)
    when 400..499
      raise ApplicationController::BadRequest, "Failed to create the ephemeral secret. Code: #{response_body['code']}, Message: #{response_body['message']}, description: #{response_body['description']}"
    else
      raise ApplicationController::InternalServerError, "Failed to create the ephemeral secret. Code: #{response_body['code']}, Message: #{response_body['message']}, description: #{response_body['description']}"
    end
  end

  protected

  def hash_keys_to_camel_case(hash, level = 0)
    result = {}
    delimiters = %w[- _]
    hash.each do |key, value|
      words = key.to_s.split(Regexp.union(delimiters))
      current_word = words[0].downcase
      (1...words.length).each do |index|
        current_word += words[index].capitalize
      end
      # If the value is another hash, perform the same casting on that sub hash.
      # We don't want unexpected behavior so currently this is limited to one level of
      result[current_word] = if value.is_a?(Hash) && level.zero?
        hash_keys_to_camel_case(value, 1)
      else
        value
      end
    end
    result
  end

  def tenant_id
    result = ENV["HOSTNAME"]
    result.split("-")[1] || ""
  rescue
    ""
  end
end
