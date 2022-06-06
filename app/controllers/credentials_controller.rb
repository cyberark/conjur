# frozen_string_literal: true

#  This class smells of :reek:RepeatedConditional for the multiple calls
# to `authentication.self?`
class CredentialsController < ApplicationController
  include BasicAuthenticator
  include TokenUser

  # Read authentication from token, basic, or CAS.
  # Some form of authentication must be provided for all methods except +authenticate+, which
  # expects the API key in the request body.
  before_action :authenticate_client

  # The username can also come from an +id+ parameter, if the operation will be performed on a different
  # user than the authenticated user.
  before_action :accept_id_parameter

  # Ensure that the referenced role exists.
  before_action :find_role

  # Token authentication cannot be used to update +self+ credentials.
  before_action :restrict_token_auth

  # Users can update their own record, and +update+ privilege on the authn service enables a superuser
  # to update any user's record.
  before_action :authorize_self_or_update, only: [ :rotate_api_key ]

  # Users are always permitted to perform some operations on their own record.
  before_action :authorize_self, except: [ :rotate_api_key ]

  # Ensure the credentials exist if they will be accessed or modified.
  before_action :ensure_credentials, only: [ :update_password, :rotate_api_key, :login ]

  # Update the authenticated user's password. The implication of this is that if you can login as a user, you can change
  # that user's password.
  #
  # This method requires a PUT request. The new password is in the request body.
  def update_password
    password = request.body.read
    raise Exceptions::Forbidden if @role.login.start_with?("host/")

    Commands::Credentials::ChangePassword.new.call(
      role: @role,
      password: password,
      client_ip: request.ip
    )

    head(204)
  end

  # Rotate a user API key.
  #
  # The new API key is in the request body.
  def rotate_api_key
    Commands::Credentials::RotateApiKey.new.call(
      role_to_rotate: authentication.apply_to_role,
      authenticated_role: authentication.authenticated_role,
      client_ip: request.ip
    )
    render(plain: @role.credentials.api_key)
  end

  protected

  def authenticate_client
    authentication.authenticated_role = Role[token_user.roleid] if token_user?
    perform_basic_authn
    raise Unauthorized, "Client not authenticated" unless authentication.authenticated?
  rescue => e
    case e
    when Errors::Authentication::Security::AccountNotDefined,
      Errors::Authentication::Security::RoleNotFound
      raise Unauthorized, "Client not authenticated"
    else
      raise e
    end
  end

  # Accept params[:role]. Later it will be ignored if it refers to the same user as the token auth.
  def accept_id_parameter
    if params[:role]
      role_id = Role.make_full_id(params[:role], account)
      authentication.selected_role = Role[role_id]

      unless authentication.selected_role
        raise Errors::Conjur::RequestedResourceNotFound.new(params[:role], authenticated_role_id)
      end
    end
    true
  end

  def find_role
    raise Unauthorized, "Role not found" unless @role = authentication.apply_to_role
  end

  # Ensure that the current role has credentials.
  def ensure_credentials
    unless @role.credentials
      Rails.logger.info(
        Errors::Authentication::RoleHasNoCredentials.new(
          @role.id
        ).message
      )
      raise Errors::Authentication::RoleNotApplicableForKeyRotation, @role.id
    end
  end

  # Don't permit token auth when manipulating 'self' record.
  def restrict_token_auth
    if authentication.self?
      raise Unauthorized, "Credential strength is insufficient" unless authentication.basic_user?
    else
      true
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

    # From this point the authenticated role is operating on another resource
    raise Unauthorized, "Operation attempted against foreign user" unless token_user?
    raise Unauthorized, "Insufficient privilege" unless authentication.authenticated_role
    raise Unauthorized, "Insufficient privilege" unless resource = @role.resource

    validate_resource_is_visible_to_role resource

    # Non actor roles (resource kind other than user/host) do not have credentials
    # If the authenticated role has ONLY read privilege return forbidden
    if not @role.credentials and role_allowed_to?("read", resource)
      raise Errors::Authorization::AccessToResourceIsForbiddenForRole.new(
        authenticated_role_id,
        resource.resource_id
      )
    end

    # The below validation will pass even if the resource has no credentials
    # but it will eventually fail in @ensure_credentials
    unless role_allowed_to?("update", resource)
      raise Errors::Authorization::InsufficientResourcePrivileges.new(
        authenticated_role_id,
        resource.resource_id
      )
    end
  end

  def validate_resource_is_visible_to_role(resource)
    unless resource.visible_to?(authenticated_role)
      # Print informative log message this is for
      # internal use only and should not be raised as an error
      # to the user not to expose the exact error
      Rails.logger.info(
        Errors::Authorization::ResourceNotVisibleToRole.new(
          resource.resource_id, authenticated_role_id
        ).message
      )

      # Raise a general record not found error
      raise Errors::Conjur::RequestedResourceNotFound.new(
        resource.resource_id, authenticated_role_id
      )
    end
  end

  def authenticated_role_id
    authenticated_role.role_id
  end

  def authenticated_role
    authentication.authenticated_role
  end

  # @return true if the authenticated role has the privilege argument on the
  # resource argument; false otherwise
  def role_allowed_to?(privilege, resource)
    authentication.authenticated_role.allowed_to?(privilege, resource)
  end

  # Read privilege is always granted.
  def authorize_self_or_read
    true
  end
end
