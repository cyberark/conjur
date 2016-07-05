class CredentialsController < ApplicationController
  include BasicAuthenticator
  include TokenUser

  # Read authentication from token, basic, or CAS.
  # Some form of authentication must be provided for all methods except +authenticate+, which
  # expects the API key in the request body.
  before_filter :authenticate_client

  # For other methods, the username can come from an +id+ parameter, or from the authenticated username.
  before_filter :find_role, only: [ :update_password, :rotate_api_key, :login, :show ]

  # Token authentication can only be used by regular users to show their own record.
  before_filter :restrict_token_auth, except: [ :show ]
  
  # Users can show their own record, and +read+ privilege on the authn service enables a superuser
  # to show any user's record.
  before_filter :authorize_self_or_read, only: [ :show ]
  # Users can update their own record, and +update+ privilege on the authn service enables a superuser
  # to update any user's record.
  before_filter :authorize_self_or_update, only: [ :rotate_api_key ]
  # Users are permitted to perform any other operation on their own record.
  before_filter :authorize_self, except: [ :show, :rotate_api_key ]

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

  def find_role
    authentication.role_id = params[:id]
    raise Unauthorized, "User not found" unless @role = authentication.database_role
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
    raise Unauthorized, "Operation attempted against foreign user" unless current_user?
    raise Unauthorized, "Insufficient privilege" unless user_resource.permitted?("update")
  end
  
  # Read privilege is always granted.
  def authorize_self_or_read
    true
  end
  
  def user_resource
    Resource[@credentials.role.id] or raise "No Resource for #{@credentials.role.id}"
  end
end
