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

    userFromCache = $redis.get(ENV['TENANT_ID'] + "::/user/" + token_user.roleid)
    if (userFromCache.nil?)
      current = Role[token_user.roleid]
      $redis.setex(ENV['TENANT_ID'] + "::/user/" + token_user.roleid, 900, current.to_json)
    else
      current = Role.new()
      current.from_json!(userFromCache)
    end
    current || raise(ApplicationController::Forbidden)
  end
end
