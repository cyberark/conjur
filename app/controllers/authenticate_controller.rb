class AuthenticateController < ApplicationController
  # Request path indicates the username for +authenticate+.
  before_filter :user_lookup

  def authenticate
    password = request.body.read
    if @user.authenticate password
      render json: authentication_token
    else
      head :unauthorized
    end
  end
  
  protected
  
  def user_lookup
    login = params[:id]
    @user = AuthnUser[login]
    raise Unauthorized, "User #{login} not found" unless @user
  end
end
