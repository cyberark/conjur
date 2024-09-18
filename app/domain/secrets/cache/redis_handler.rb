# frozen_string_literal: true
module Secrets
  module RedisHandler

    OK = 'OK' # Redis response for creation success
    PREFIXES = {
      secret: '',
      resource: "secrets/resource/",
      user: "user/",
      role_membership: "{role_membership}/" # in {} to avoid Redis limitation for delete_matched on cluster. see https://redis.io/docs/latest/commands/keys/
    }

    #Secrets
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

      delete_from_redis(:secret, key)
    rescue => e
      Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Delete', e.message))
      raise e
    end

    # Resources
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
      delete_from_redis(:resource, resource_id)
    rescue => e
      Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Delete resource', e.message))
      raise e
    end

    # Role membership

    # @param: role_id
    # @param: block for retrieving membership from DB
    def get_role_membership(role_id)
      return yield unless redis_configured?

      role_membership = nil
      begin
        role_membership = read_from_redis(:role_membership, role_id)
      rescue => e
        Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Read role membership', e.message))
      end
      if role_membership.nil?
        role_membership = yield
        begin
          write_to_redis(:role_membership, role_id, role_membership)
        rescue => e
          Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Write role membership', e.message))
        end
      end
      role_membership
    end

    def clean_membership_cache
      begin
        Rails.cache.delete_matched("#{PREFIXES[:role_membership]}*") if Rails.application.config.conjur_config.try(:conjur_edge_is_atlantis)
      rescue  => e
        Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Delete role membership', e.message))
      end
    end

    ## User
    def create_redis_user(role_id, value)
      return OK unless redis_configured?
      write_user(role_id, value)
    rescue => e
      Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Write user', e.message))
      return 'false'
    end

    def get_redis_user(role_id)
      return nil unless redis_configured?
      read_user(role_id)
    rescue => e
      Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Read user', e.message))
      return nil
    end

    def delete_redis_user(resource_id)
      return unless redis_configured?
      delete_from_redis(:user, resource_id)
    rescue => e
      Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Delete user', e.message))
      raise e
    end

    def redis_configured?
      Rails.configuration.cache_store.include?(:redis_cache_store)
    end

    private

    def versioned_key(key, version)
      return version ? key + "?version=" + version : key
    end

    def read_user(key)
      read_from_redis(:user, key)
    end

    def write_user(key, value)
      write_to_redis(:user, key, value)
    end

    def read_secret(key)
      result = read_from_redis(:secret, key)
      Slosilo::EncryptedAttributes.decrypt(result, aad: key)
    end

    def write_secret(key, value)
      write_to_redis(:secret, key, Slosilo::EncryptedAttributes.encrypt(value, aad: key))
    end

    def read_resource(key)
      read_from_redis(:resource, key)
    end

    def write_resource(key, value)
      write_to_redis(:resource, key, value)
    end

    def read_from_redis(type, key)
      Rails.logger.debug{LogMessages::Redis::RedisAccessStart.new('Read')}
      value = Rails.cache.read(PREFIXES[type] + key)
      is_found = value.nil? ? "not " : ""
      Rails.logger.debug{LogMessages::Redis::RedisAccessEnd.new('Read', "#{type} #{key} was #{is_found} in Redis")}
      value
    end

    def write_to_redis(type, key, value)
      Rails.logger.debug{LogMessages::Redis::RedisAccessStart.new('Write')}
      response = Rails.cache.write(PREFIXES[type]  + key, value)
      Rails.logger.debug{LogMessages::Redis::RedisAccessEnd.new("write #{type}", response)}
      response
    end

    def delete_from_redis(type, key)
      Rails.logger.debug{LogMessages::Redis::RedisAccessStart.new('Delete')}
      response = Rails.cache.delete(PREFIXES[type]  + key)
      Rails.logger.debug{LogMessages::Redis::RedisAccessEnd.new('Delete', "Deleted #{response} items")}
    end

    def secret_applicable?(key)
      redis_configured? &&
      key.split(':').last.start_with?('data')
    end

  end
end
