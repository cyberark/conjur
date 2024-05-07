# frozen_string_literal: true
require_relative '../../domain/secrets/cache/redis_handler'

module CurrentUser
  extend ActiveSupport::Concern

  included do
    include TokenUser
    include Secrets::RedisHandler
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

  def find_current_user
    user_in_cache = get_redis_user(token_user.roleid)
    if user_in_cache.nil?
      current_user = Role[token_user.roleid]
      create_redis_user(token_user.roleid, current_user.to_hash!)
    else
      current_user = Role.new
      current_user.from_hash!(user_in_cache)
    end
    current_user || raise(ApplicationController::Forbidden)
  end

end