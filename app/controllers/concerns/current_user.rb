# frozen_string_literal: true

module CurrentUser
  extend ActiveSupport::Concern

  included do
    include TokenUser
  end

  def current_user?
    begin
      current_user
    rescue Forbidden => e
      nil
    end
  end

  def current_user
    @current_user ||= find_current_user
  end

  private

  USER_PATTERN = "user/"

  def find_current_user
    user_in_cache = get_redis_user(token_user.roleid)
    if user_in_cache.nil?
      current_user = Role[token_user.roleid]
      create_redis_user(token_user.roleid, current_user.to_json)
    else
      current_user = Role.new
      current_user.from_json!(user_in_cache)
    end
    current_user || raise(ApplicationController::Forbidden)
  end

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
    return OK unless redis_configured?
    read_user(role_id)
  rescue => e
    Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Read user', e.message))
    return nil
  end

  def redis_configured?
    Rails.configuration.cache_store.include?(:redis_cache_store)
  end

end