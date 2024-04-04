# frozen_string_literal: true
module Secrets
  module RedisHandler

    def get_redis_secret(key, version = nil)
      return nil, nil unless secret_applicable?(key)
      versioned_key = versioned_key(key, version)

      value = read_resource(versioned_key)
      mime_type = read_resource(key + '/mime_type') || SecretsController::DEFAULT_MIME_TYPE
      # Returns non-nil value if found in Redis. mime_type is never nil
      return value, mime_type
    rescue => e
      Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Read', e.message))
      return nil, nil
    end

    def create_redis_secret(key, value, mime_type, version = nil)
      return unless secret_applicable?(key)

      versioned_key = versioned_key(key, version)

      write_resource(versioned_key, value)
      if mime_type != SecretsController::DEFAULT_MIME_TYPE # We save mime_type only if it's not default
        write_resource(key + '/mime_type', mime_type)
      end
    rescue => e
      Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Write', e.message))
    end

    # Updates secret value if exists
    def update_redis_secret(key, value)
      value_in_redis, mime_type = get_redis_secret(key)
      unless value_in_redis.nil? # Only update secret. Don't create a new one
        create_redis_secret(key, value, mime_type)
      end
    rescue => e
      Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Update', e.message))
    end

    def delete_redis_secret(key)
      return unless secret_applicable?(key)

      Rails.logger.debug(LogMessages::Redis::RedisAccessStart.new('Delete'))
      response = Rails.cache.delete(key)
      Rails.logger.debug(LogMessages::Redis::RedisAccessEnd.new('Delete', "Deleted #{response} items"))
    rescue => e
      Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Delete', e.message))
    end

    def redis_configured?
      Rails.configuration.cache_store.include?(:redis_cache_store)
    end

    private

    def versioned_key(key, version)
      return version ? key + "?version=" + version : key
    end

    def read_resource(key)
      Rails.logger.debug(LogMessages::Redis::RedisAccessStart.new('Read'))
      value = Rails.cache.read(key)&.
          yield_self {|res| Slosilo::EncryptedAttributes.decrypt(res, aad: key)}
      is_found = value.nil? ? "not " : ""
      Rails.logger.debug(LogMessages::Redis::RedisAccessEnd.new('Read', "Secret #{key} was #{is_found} in Redis"))
      value
    end

    def write_resource(key, value)
      Rails.logger.debug(LogMessages::Redis::RedisAccessStart.new('Write'))
      response = Slosilo::EncryptedAttributes.encrypt(value, aad: key)
                                             .yield_self {|val| Rails.cache.write(key, val)}
      Rails.logger.debug(LogMessages::Redis::RedisAccessEnd.new('write', response))
    end

    def secret_applicable?(key)
      redis_configured? &&
      key.split(':').last.start_with?('data')
    end

  end
end
