# frozen_string_literal: true
module FindIssuerResource
  include FindResource
  include AccountValidator
  extend ActiveSupport::Concern

  def resource_id
    if request.request_method == "GET" && request.filtered_parameters[:action] == "get"
      [ account, "policy", "conjur/issuers/#{params[:identifier]}" ].join(":")
    else
      [ account, "policy", "conjur/issuers" ].join(":")
    end
  end

  def find_or_create_root_policy
    validate_account(account)
    Loader::Types.find_or_create_root_policy(account)
  end

  def account
    @account ||= params[:account]
  end

end