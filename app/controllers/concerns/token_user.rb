# frozen_string_literal: true

module TokenUser
  extend ActiveSupport::Concern

  def token_user?
    request.env['conjur-token-authentication.token_details'].present?
  end

  def token_user
    request.env['conjur-token-authentication.token_details']
  end
end
