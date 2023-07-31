# frozen_string_literal: true
module FindPlatformResource
  include FindResource
  extend ActiveSupport::Concern

  def resource_id
    if request.request_method == "GET" && request.filtered_parameters[:action] == "get"
      [ account, "policy", "data/platforms/#{params[:identifier]}" ].join(":")
    else
      [ account, "policy", "data/platforms" ].join(":")
    end
  end

  def find_or_create_root_policy
    Loader::Types.find_or_create_root_policy(account)
  end

  def account
    @account ||= params[:account]
  end

end