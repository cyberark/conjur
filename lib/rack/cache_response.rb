# frozen_string_literal: true

require 'pp'
require 'json'

class CachedEndpoint
  extend CommandClass::Include

  command_class(
    dependencies: {
      app: nil,
      path: nil,
      request_name: nil,
      cache: Rails.cache,
      encryption_algorithm: Slosilo::EncryptedAttributes,
      http_method: 'GET'
    },
    inputs: %i[env auth_secret]
  ) do

    def call
      # Do nothing, if path doesn't match.
      return nil unless @path =~ @env['PATH_INFO'] && @http_method == @env['REQUEST_METHOD']

      # Return cached value, if found.
      cached_resp = cached_response
      return cached_resp if cached_resp

      status, header, rackBody = @app.call(@env)
      response = [status, header, [rackBody.body]]
      return response if status >= 300

      @cache.write(
        store_key,
        @encryption_algorithm.encrypt(
          JSON.dump({
            auth_secret: @auth_secret,
            http_status: status,
            http_header: header,
            http_body: [rackBody.body]
          }),
          aad: @req_path
        ),
        expires_in: 60
      )
      response
    end

    def store_key
      # TODO: confirm REMOTE_IP is what we need, and what we need for req path
      # @store_key ||= JSON.dump([@env['REQUEST_PATH'], @env['REMOTE_IP'], "login"])
      # TODO: remove this dep
      req = ActionDispatch::Request.new(@env)
      @store_key ||= JSON.dump([req.path, req.ip, @request_name])
    end

    def cached_response
      encrypted_cached_value = @cache.fetch(store_key)
      return nil unless encrypted_cached_value

      # Use request path as salt.  This should be safe, since salts are not
      # sensitive.
      decrypted_cached_value = @encryption_algorithm.decrypt(
        encrypted_cached_value,
        aad: @req_path
      )
      cached_resp = JSON.parse(decrypted_cached_value)
      return nil unless @auth_secret == cached_resp["auth_secret"]
      [
        cached_resp["http_status"],
        cached_resp["http_header"],
        cached_resp["http_body"]
      ]
    end
  end
end

module Rack
  class CacheResponse
    def initialize(app)
      @app = app
      @login_cache = CachedEndpoint.new(
        request_name: 'login',
        app: @app,
        path: %r{^/authn/.*/login$}
      )
      @secret_cache = CachedEndpoint.new(
        request_name: 'secrets',
        app: @app,
        path: %r{^/secrets/.*$}
      )
      @authenticate_cache = CachedEndpoint.new(
        request_name: 'authenticate',
        app: @app,
        path: %r{^/authn/.*/authenticate$},
        http_method: 'POST'
      )
    end


    def call(env)
      # TODO: remove dep on Rails::Dispatch
      # env['rack.input'].gets
      # msg = JSON.parse env['rack.input'].read
      # https://stackoverflow.com/questions/9707034/how-to-receive-a-json-object-with-rack
      # Then we can pass our object nothing but env as input.
      req = ActionDispatch::Request.new(env)
      req_body = req.body.read
      req.body.rewind

      result = @secret_cache.call(env: env, auth_secret: req_body)
      return result if result
      result = @authenticate_cache.call(env: env, auth_secret: req_body)
      return result if result
      result = @login_cache.call(env: env, auth_secret: env['HTTP_AUTHORIZATION'])
      return result if result

      status, header, rackBody = @app.call(env)
      if status < 300 && env['REQUEST_METHOD'] != "GET"
        print("Cleared the cache")
        Rails.cache.clear
      end
      [status, header, [rackBody.body]]
    end
  end
end
