class CredentialsController < ApplicationController
  include BasicAuthenticator
  include TokenUser

  # Read authentication from token, basic, or CAS.
  # Some form of authentication must be provided for all methods except +authenticate+, which
  # expects the API key in the request body.
  before_filter :authenticate_client

  # The username can also come from an +id+ parameter, if the operation will be performed on a different
  # user than the authenticated user.
  before_filter :accept_id_parameter
    
  # Ensure that the referenced role exists.
  before_filter :find_role

  # Token authentication cannot be used to update +self+ credentials.
  before_filter :restrict_token_auth
  
  # Users can update their own record, and +update+ privilege on the authn service enables a superuser
  # to update any user's record.
  before_filter :authorize_self_or_update, only: [ :rotate_api_key ]
    
  # Users are always permitted to perform some operations on their own record.
  before_filter :authorize_self, except: [ :rotate_api_key ]

  # Ensure the credentials exist if they will be accessed or modified.
  before_filter :ensure_credentials, only: [ :update_password, :rotate_api_key, :login ]
    
  # Update the authenticated user's password. The implication of this is that if you can login as a user, you can change
  # that user's password.
  #
  # This method requires a PUT request. The new password is in the request body.
  def update_password
    password = request.body.read
    if password.blank?
      render json: { password: "must not be blank" }, status: :unprocessable_entity
      return
    end
    
    @role.credentials.password = password
    save_credentials do
      head 204
    end
  end
  
  # Rotate a user API key.
  #
  # The new API key is in the request body.
  def rotate_api_key
    @role.credentials.rotate_api_key
    save_credentials do
      render text: @role.credentials.api_key
    end
  end
  
  def login
    render text: @role.credentials.api_key
  end
  
  protected
  
  def save_credentials
    if @role.credentials.save
      yield
    else
      render json: @credentials.errors, status: :unprocessable_entity
    end
  end
  
  def authenticate_client
    authentication.token_user = token_user if token_user?
    perform_basic_authn
    raise Unauthorized, "Client not authenticated" unless authentication.authenticated?
  end

  # Accept params[:id], but ignore it if it refers to the same user as the token auth.
  def accept_id_parameter
    if params[:id]
      id_roleid = roleid_from_username(params[:id])
      unless token_user? && id_roleid == roleid_from_username(token_user.login)
        authentication.role_id = id_roleid
      end
    end
    true
  end
      
  def find_role
    raise Unauthorized, "User not found" unless @role = authentication.database_role
  end
  
  # Ensure that the current role has credentials.
  def ensure_credentials
    @role.credentials ||= Credentials.new(role: @role)
  end
  
  # Don't permit token auth when manipulating 'self' record.
  def restrict_token_auth
    if authentication.role_id
      true
    else
      raise Unauthorized, "Credential strength is insufficient" unless authentication.basic_user
    end
  end

  # The authenticated user represents a user in this account.
  def authorize_self
    raise Unauthorized, "Operation attempted against foreign user" unless authentication.self?
  end
  
  # The operation is allowed on the authenticated user's own record, or on the record
  # indicated by +id+ if the authenticated user has +update+ privilege on the authn service.
  def authorize_self_or_update
    return true if authentication.self?
    raise Unauthorized, "Operation attempted against foreign user" unless token_user?
    raise Unauthorized, "Insufficient privilege" unless token_role = Role[roleid_from_username(token_user.login)]
    raise Unauthorized, "Insufficient privilege" unless resource = @role.resource
    raise Unauthorized, "Insufficient privilege" unless token_role.allowed_to? "update", resource
  end
  
  # Read privilege is always granted.
  def authorize_self_or_read
    true
  end
end
