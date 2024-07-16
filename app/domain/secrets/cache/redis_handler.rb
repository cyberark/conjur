# frozen_string_literal: true
module Secrets
  module RedisHandler

    OK = 'OK' # Redis response for creation success
    RESOURCE_PREFIX = "secrets/resource/"
    USER_PATTERN = "user/"

    def get_redis_secret(key, version = nil)
      return nil, nil unless secret_applicable?(key)
      versioned_key = versioned_key(key, version)

      value = read_secret(versioned_key)
      mime_type = read_secret(key + '/mime_type') || SecretsController::DEFAULT_MIME_TYPE
      # Returns non-nil value if found in Redis. mime_type is never nil
      return value, mime_type
    rescue => e
      Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Read', e.message))
      return nil, nil
    end

    # Returns OK if no error occurred, not necessarily write in Redis
    def create_redis_secret(key, value, mime_type, version = nil)
      return OK unless secret_applicable?(key)

      versioned_key = versioned_key(key, version)

      value_res = write_secret(versioned_key, value)
      if mime_type != SecretsController::DEFAULT_MIME_TYPE # We save mime_type only if it's not default
        write_secret(key + '/mime_type', mime_type)
      end
      return value_res
    rescue => e
      Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Write', e.message))
      return 'false'
    end

    def delete_redis_secret(key)
      return unless secret_applicable?(key)

      Rails.logger.debug(LogMessages::Redis::RedisAccessStart.new('Delete'))
      response = Rails.cache.delete(key)
      Rails.logger.debug(LogMessages::Redis::RedisAccessEnd.new('Delete', "Deleted #{response} items"))
    rescue => e
      Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Delete', e.message))
      raise e
    end

    def get_redis_resource(resource_id)
      return nil unless redis_configured?
      read_resource(resource_id)
    rescue => e
      Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Read resource', e.message))
      return nil
    end

    def create_redis_resource(resource_id, value)
      return OK unless redis_configured?
      write_resource(resource_id, value)
    rescue => e
      Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Write resource', e.message))
      return 'false'
    end

    def delete_redis_resource(resource_id)
      return unless redis_configured?
      Rails.logger.debug(LogMessages::Redis::RedisAccessStart.new('Delete'))
      response = Rails.cache.delete(resource_id)
      Rails.logger.debug(LogMessages::Redis::RedisAccessEnd.new('Delete', "Deleted #{response} items"))
    rescue => e
      Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Delete resource', e.message))
      raise e
    end

    def redis_configured?
      Rails.configuration.cache_store.include?(:redis_cache_store)
    end

    ## User
    def create_redis_user(role_id, value)
      return OK unless redis_configured?
      write_user(role_id, value)
    rescue => e
      Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Write user', e.message))
      return 'false'
    end

    def write_user(key, value)
      Rails.logger.debug(LogMessages::Redis::RedisAccessStart.new('Write'))
      response = Rails.cache.write(USER_PATTERN + key, value)
      Rails.logger.debug(LogMessages::Redis::RedisAccessEnd.new('write user', response))
      response
    end

    def read_user(key)
      Rails.logger.debug(LogMessages::Redis::RedisAccessStart.new('Read'))
      value = Rails.cache.read(USER_PATTERN + key)
      is_found = value.nil? ? "not " : ""
      Rails.logger.debug(LogMessages::Redis::RedisAccessEnd.new('Read', "User #{key} was #{is_found} in Redis"))
      value
    end
    def get_redis_user(role_id)
      return nil unless redis_configured?
      read_user(role_id)
    rescue => e
      Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Read user', e.message))
      return nil
    end

    private

    def versioned_key(key, version)
      return version ? key + "?version=" + version : key
    end

    def read_secret(key)
      Rails.logger.debug(LogMessages::Redis::RedisAccessStart.new('Read'))
      value = Rails.cache.read(key)&.
        yield_self {|res| Slosilo::EncryptedAttributes.decrypt(res, aad: key)}
      is_found = value.nil? ? "not " : ""
      Rails.logger.debug(LogMessages::Redis::RedisAccessEnd.new('Read', "Secret #{key} was #{is_found} in Redis"))
      value
    end

    def read_resource(key)
      Rails.logger.debug(LogMessages::Redis::RedisAccessStart.new('Read'))
      value = Rails.cache.read(RESOURCE_PREFIX + key)
      is_found = value.nil? ? "not " : ""
      Rails.logger.debug(LogMessages::Redis::RedisAccessEnd.new('Read', "Resource #{key} was #{is_found} in Redis"))
      value
    end

    def write_resource(key, value)
      Rails.logger.debug(LogMessages::Redis::RedisAccessStart.new('Write'))
      response = Rails.cache.write(RESOURCE_PREFIX + key, value)
      Rails.logger.debug(LogMessages::Redis::RedisAccessEnd.new('write resource', response))
      response
    end

    def write_secret(key, value)
      Rails.logger.debug(LogMessages::Redis::RedisAccessStart.new('Write'))
      response = Slosilo::EncryptedAttributes.encrypt(value, aad: key)
                                             .yield_self {|val| Rails.cache.write(key, val)}
      Rails.logger.debug(LogMessages::Redis::RedisAccessEnd.new('write secret', response))
      response
    end

    def secret_applicable?(key)
      redis_configured? &&
      key.split(':').last.start_with?('data')
    end

  end
end
