# frozen_string_literal: true

require 'date'

class StatusController < ApplicationController
  include TokenUser

  def index
    render 'index', layout: false
  end

  # /whoami returns basic information about the request client and access token
  # that Conjur receives.
  #
  # This is useful for troubleshooting authentication with access tokens and
  # configuring proxies or load balancers.
  def whoami
    render json: { 
      client_ip: request.ip,
      user_agent: request.user_agent,
      account: token_user.account,
      username: token_user.login,
      token_issued_at: Time.at(token_user.token.claims["iat"])
    }
  end
end
