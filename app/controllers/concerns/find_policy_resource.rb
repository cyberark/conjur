# frozen_string_literal: true
module FindPolicyResource
  include FindResource
  extend ActiveSupport::Concern

  def resource_id
    [ params[:account], "policy", params[:identifier] ].join(":")
  end

  def find_or_create_root_policy
    Loader::Types.find_or_create_root_policy(account)
  end

  def account
    @account ||= params[:account]
  end

end