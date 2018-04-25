require 'authentication/strategy'
require 'authentication/installed_authenticators'

class AuthenticateController < ApplicationController

  def authenticate

    # TODO move the Strategy into an initializer
    #
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
    puts '*******************************'
    puts e.message
    raise e
    logger.debug(e.message)
    raise Unauthorized
  end

end
