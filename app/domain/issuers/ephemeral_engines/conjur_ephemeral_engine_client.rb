# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

require_relative('ephemeral_engine_client')

class ConjurEphemeralEngineClient
  include EphemeralEngineClient

  @@secrets_service_address = ENV['EPHEMERAL_SECRETS_SERVICE_ADDRESS'] || "ephemeral-secrets"
  @@secrets_service_port = ENV['EPHEMERAL_SECRETS_SERVICE_PORT'] || "8080"

  def initialize(logger:, request_id:, http_client: nil)
    if http_client
      @client = http_client
    else
      @client = Net::HTTP.new(@@secrets_service_address, @@secrets_service_port.to_i)
      @client.use_ssl = false  # Service mesh takes care of the TLS communication
    end
    @logger = logger
    @request_id = request_id
  end

  def get_ephemeral_secret(type, method, role_id, issuer_data, variable_data)
    request_body = {
      type: type,
      method: method,
      role: role_id,
      issuer: hash_keys_to_snake_case(issuer_data),
      secret: hash_keys_to_snake_case(variable_data)
    }

    # Create the POST request
    secret_request = Net::HTTP::Post.new("/secrets")
    secret_request.body = request_body.to_json

    # Add headers
    secret_request.add_field('Content-Type', 'application/json')
    secret_request.add_field('X-Request-ID', @request_id)
    secret_request.add_field('X-Tenant-ID', tenant_id)

    # Send the request and get the response
    @logger.debug(LogMessages::Secrets::EphemeralSecretRequestBody.new(@request_id, secret_request.body))
    begin
      response = @client.request(secret_request)
    rescue => e
      @logger.error(LogMessages::Secrets::EphemeralSecretRemoteRequestFailure.new(@request_id, e.message))
      raise ApplicationController::InternalServerError, e.message
    end
    @logger.debug(LogMessages::Secrets::EphemeralSecretRemoteResponse.new(@request_id, response.code))

    case response.code.to_i
    when 200..299
      return response.body
    else
      response_body = JSON.parse(response.body)
      @logger.error(LogMessages::Secrets::EphemeralSecretRemoteResponseFailure.new(@request_id, response_body['code'], response_body['message'], response_body['description']))
      raise ApplicationController::UnprocessableEntity, "Failed to create the ephemeral secret. Code: #{response_body['code']}, Message: #{response_body['message']}, description: #{response_body['description']}"
    end
  end

  protected

  def hash_keys_to_snake_case(hash, level = 0)
    result = {}
    hash.each do |key, value|
      transformed_key = key.to_s.gsub("-", "_").downcase

      # If the value is another hash, perform the same casting on that sub hash.
      # We don't want unexpected behavior so currently this is limited to one level of
      result[transformed_key] = if value.is_a?(Hash) && level.zero?
        hash_keys_to_snake_case(value, 1)
      else
        value
      end
    end
    result
  end

  def tenant_id
    Rails.application.config.conjur_config.tenant_id
  end
end
