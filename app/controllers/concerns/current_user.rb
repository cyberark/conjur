# frozen_string_literal: true
require 'json'

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

  def find_current_user

    userFromCache = $redis.get("user/" + token_user.roleid)
    #Rails.logger.info("+++++++++++++++ userFromCache = #{userFromCache}, token_user.roleid = #{token_user.roleid}")
    if (userFromCache.nil?)
      current = Role[token_user.roleid]
      #Rails.logger.info("+++++++++++++++ current.to_json = #{current.to_json}")
      $redis.setex("user/" + token_user.roleid, 5, current.to_json)
    else
      current = Role.new()
      current.from_json!(userFromCache)
    end
    current || raise(ApplicationController::Forbidden)
  end
end
