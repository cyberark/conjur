class AuthenticateController < ApplicationController
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
  
  def signing_key
    Slosilo["authn:#{account}".to_sym] or raise Unauthorized, "No signing key is available for account '#{account}'"
  end
    
  def authentication_token
    signing_key.signed_token Role.username_from_roleid(@credentials.role.id)
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
