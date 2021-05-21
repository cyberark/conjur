# frozen_string_literal: true

require 'pp'
require 'json'

module Rack
  class CacheResponse
    def initialize(app)
      @app = app
    end

    def call(env)
      start_time = Time.now

      req = ActionDispatch::Request.new(env)
      req_body = req.body.read
      # Bring it back to original state
      req.body.rewind
      req_path = req.path

      if req_path.match?(%r{^/authn/.*/login$}) && env['REQUEST_METHOD'] == "GET"
        redis_key = JSON.dump(
          [req_path, req.ip, "login"]
        )
        redis_value = Rails.cache.fetch(redis_key)
        ### Check if salt is secure enough
        if redis_value
          marshaled_string = Slosilo::EncryptedAttributes.decrypt(
            redis_value, aad: req_path
          )
          value = JSON.parse(marshaled_string)
          if env['HTTP_AUTHORIZATION'] == value[0]
            puts("Hit login cache")
            end_time = Time.now
            puts("TOTAL TIME: #{end_time - start_time}")
            return [value[1].to_i, value[2], value[3]]
          end
        end
      elsif req_path.match?(%r{^/authn/.*/authenticate$}) && env['REQUEST_METHOD'] == "POST"
        redis_key = JSON.dump(
          [req_path, req.ip, "authenticate"]
        )
        redis_value = Rails.cache.fetch(redis_key)
        ### Check if salt is secure enough
        if redis_value
          marshaled_string = Slosilo::EncryptedAttributes.decrypt(
            redis_value, aad: req_path
          )
          value = JSON.parse(marshaled_string)
          if req_body == value[0]
            puts("Hit authenticate cache")
            end_time = Time.now
            puts("TOTAL TIME: #{end_time - start_time}")
            return [value[1].to_i, value[2], value[3]]
          end
        end
      elsif req_path.match?(%r{^/secrets/.*$}) && env['REQUEST_METHOD'] == "GET"
        redis_key = JSON.dump(
          [req_path, req.ip, "secret_retrieval"]
        )
        redis_value = Rails.cache.fetch(redis_key)
        ### Check if salt is secure enough
        if redis_value
          marshaled_string = Slosilo::EncryptedAttributes.decrypt(
            redis_value, aad: req_path
          )
          value = JSON.parse(marshaled_string)
          print(req_body)
          print(value[0])
          if req_body == value[0]
            puts("Hit secrets cache")
            end_time = Time.now
            puts("TOTAL TIME: #{end_time - start_time}")
            return [value[1].to_i, value[2], value[3]]
          end
        end
      end
      
      status, header, rackBody = @app.call(env)
      if status < 300
        if req_path.match?(%r{^/authn/.*/login$})
          redis_key = JSON.dump(
            [req_path, req.ip, "login"]
          )
          Rails.cache.write(
            redis_key,
            Slosilo::EncryptedAttributes.encrypt(
              JSON.dump(
                [env['HTTP_AUTHORIZATION'], status, header, [rackBody.body]]
              ), aad: req_path
            ), expires_in: 60
          )
          end_time = Time.now
          puts("TOTAL TIME: #{end_time - start_time}")
          print("Cached login response")
        elsif req_path.match?(%r{^/authn/.*/authenticate$})
          redis_key = JSON.dump(
            [req_path, req.ip, "authenticate"]
          )
          Rails.cache.write(
            redis_key,
            Slosilo::EncryptedAttributes.encrypt(
              JSON.dump(
                [req_body, status, header, [rackBody.body]]
              ), aad: req_path
            ), expires_in: 60
          )
          end_time = Time.now
          puts("TOTAL TIME: #{end_time - start_time}")
          print("Cached authenticate response")
        elsif req_path.match?(%r{^/secrets/.*$})
          if env['REQUEST_METHOD'] == "GET"
            redis_key = JSON.dump(
              [req_path, req.ip, "secret_retrieval"]
            )
            Rails.cache.write(
              redis_key,
              Slosilo::EncryptedAttributes.encrypt(
                JSON.dump(
                  [req_body, status, header, [rackBody.body]]
                ), aad: req_path
              ), expires_in: 60
            )
          elsif env['REQUEST_METHOD'] != "GET"
            # Secret updated
            print("Cleared the cache")
            Rails.cache.clear
          end
          end_time = Time.now
          puts("TOTAL TIME: #{end_time - start_time}")
          print("Cached secret response")
        end 
      end
      [status, header, [rackBody.body]]
    end
  end
end
