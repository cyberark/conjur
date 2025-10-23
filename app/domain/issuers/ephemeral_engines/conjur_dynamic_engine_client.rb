# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module Issuers
  module EphemeralEngines
    class ConjurDynamicEngineClient < DynamicEngineClient

      def initialize(
        logger:,
        request_id:,
        http_client:
      )
        @client = http_client
        @logger = logger
        @request_id = request_id
      end

      def dynamic_secret(type, method, role_id, issuer_data, variable_data)
        request_body = {
          type: type,
          method: method,
          role: role_id,
          issuer: ConjurDynamicEngineClient.normalize_hash_keys(issuer_data),
          secret: ConjurDynamicEngineClient.normalize_hash_keys(variable_data)
        }

        # Create the POST request
        secret_request = Net::HTTP::Post.new("/secrets")
        secret_request.body = request_body.to_json

        # Add headers
        secret_request.add_field('Content-Type', 'application/json')
        secret_request.add_field('X-Request-ID', @request_id)

        # Filter out sensitive data from the request body and log the request
        request_body[:issuer]["data"].delete("secret_access_key")
        request_to_log = request_body.to_json
        # Send the request and get the response
        @logger.debug{LogMessages::Secrets::DynamicSecretRequestBody.new(@request_id, request_to_log)}
        begin
          response = @client.request(secret_request)
        rescue => e
          @logger.error(LogMessages::Secrets::DynamicSecretRemoteRequestFailure.new(@request_id, e.message))
          raise ApplicationController::InternalServerError, e.message
        end
        @logger.debug{LogMessages::Secrets::DynamicSecretRemoteResponse.new(@request_id, response.code)}

        case response.code.to_i
        when 200..299
          response.body
        else
          response_body = JSON.parse(response.body)
          @logger.error(
            LogMessages::Secrets::DynamicSecretRemoteResponseFailure.new(
              @request_id,
              response_body['code'],
              response_body['message'],
              response_body['description']
            )
          )
          raise ApplicationController::UnprocessableEntity,
                "Failed to create the dynamic secret. Code: " \
                "#{response_body['code']}, Message: #{response_body['message']}, " \
                "description: #{response_body['description']}"
        end
      end

      def self.normalize_hash_keys(hash, level = 0)
        result = {}
        hash.each do |key, value|
          transformed_key = key.to_s.gsub("-", "_").downcase

          # If the value is another hash, perform the same casting on that sub hash.
          # We don't want unexpected behavior so currently this is limited to
          # one level of normalization.
          result[transformed_key] = if value.is_a?(Hash) && level.zero?
            normalize_hash_keys(value, 1)
          else
            value
          end
        end
        result
      end
    end
  end
end
