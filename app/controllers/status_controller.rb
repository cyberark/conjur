# frozen_string_literal: true

require 'date'

class StatusController < ActionController::API
  include TokenUser

  def index
    render('index', layout: false)
  end

  # /whoami returns basic information about the request client and access token
  # that Conjur receives.
  #
  # This is useful for troubleshooting authentication with access tokens and
  # configuring proxies or load balancers.
  def whoami
    audit_success

    render(json: {
      client_ip: request.ip,
      user_agent: request.user_agent,
      account: token_user.account,
      username: token_user.login,
      token_issued_at: Time.at(token_user.token.claims["iat"])
    })
  end

  def audit_success
    Audit.logger.log(
      Audit::Event::Whoami.new(
        client_ip: token_user.remote_ip,
        role: ::Role.by_login(token_user.login, account: token_user.account),
        success: true
      )
    )
  end
end
