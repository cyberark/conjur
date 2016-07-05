class AuthenticateController < ApplicationController
  # Request path indicates the username for +authenticate+.
  before_filter :credentials_lookup

  def authenticate
    password = request.body.read
    if @credentials.authenticate password
      render json: authentication_token
    else
      head :unauthorized
    end
  end
  
  protected
  
  def authentication_token
    Slosilo[:own].signed_token Role.username_from_roleid(@credentials.role.id)
  end

  def credentials_lookup
    roleid = roleid_from_username(params[:id])
    @credentials = Credentials[roleid]
    unless @credentials
      logger.debug "Credentials for #{roleid} not found"
      raise Unauthorized 
    end
  end
end
