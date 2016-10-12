class AuthenticateController < ApplicationController
  include TokenGenerator

  # Request path indicates the username for +authenticate+.
  before_filter :credentials_lookup

  def authenticate
    api_key = request.body.read
    if @credentials.valid_api_key? api_key
      render json: authentication_token
    else
      head :unauthorized
    end
  end
  
  protected
  
  def authentication_token
    sign_token @credentials.role
  end

  def credentials_lookup
    roleid = Role.roleid_from_username(account, params[:id])
    @credentials = Credentials[roleid]
    unless @credentials
      logger.debug "Credentials for #{roleid} not found"
      raise Unauthorized 
    end
  end
end
