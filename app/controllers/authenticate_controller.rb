class AuthenticateController < ApplicationController

  def authenticate

    authentication_token = ::Authentication::Strategy.new(
      authenticators: ::Authentication::InstalledAuthenticators.new(ENV),
      security: nil,
      env: ENV,
      role_class: ::Authentication::MemoizedRole,
      token_factory: TokenFactory.new
    ).conjur_token(
      ::Authentication::Strategy::Input.new(
        authenticator_name: params[:authenticator],
        service_id:         params[:service_id],
        account:            params[:account],
        username:           params[:id],
        password:           request.body.read
      )
    )
    render json: authentication_token
  rescue => e
    logger.debug("Authentication Error: #{e.message}")
    raise Unauthorized
  end

end
