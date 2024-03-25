# frozen_string_literal: true
module Secrets
  module RedisHandler
    def get_redis_secret(key, version = nil)
      return nil, nil if !secret_applicable?(key) || version # We currently don't support version

      value =  Rails.cache.read(prefix_secret_key(key))
      if value
        Rails.logger.debug(LogMessages::Redis::RedisAccessStart.new('Read'))
        mime_type = Rails.cache.read(prefix_secret_key(key) + "/mime_type")
        return value, mime_type
      else
        Rails.logger.debug(LogMessages::Redis::RedisAccessEnd.new('Read', 'Secret was not found in Redis'))
        return nil, nil
      end
    rescue => e
      Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Read', e.message))
      return nil, nil
    end

    def create_redis_secret(key, value, mime_type)
      return unless secret_applicable?(key)

      Rails.logger.debug(LogMessages::Redis::RedisAccessStart.new('Write'))
      response = Rails.cache.write(prefix_secret_key(key), value)
      Rails.logger.debug(LogMessages::Redis::RedisAccessEnd.new('write', response))
      if mime_type != SecretsController::DEFAULT_MIME_TYPE # We save mime_type only if it's not default
        response = Rails.cache.write(prefix_secret_key(key) + "/mime_type", mime_type)
        Rails.logger.debug(LogMessages::Redis::RedisAccessEnd.new('write', response))
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

    private

    def prefix_secret_key(key)
      '/secrets/' + key
    end

    def secret_applicable?(key)
      redis_configured? &&
      key.start_with?('data')
    end

    def redis_configured?
      Rails.configuration.cache_store.include?(:redis_cache_store)
    end
  end
end
