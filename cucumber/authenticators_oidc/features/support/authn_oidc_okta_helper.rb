# frozen_string_literal: true
require 'securerandom'

# Utility methods for OIDC authenticator
module AuthnOidcHelper
  private

  def okta_client_id
    @okta_client_id ||= validated_env_var('OKTA_CLIENT_ID')
  end

  def okta_client_secret
    @okta_client_secret ||= validated_env_var('OKTA_CLIENT_SECRET')
  end

  def okta_provider_uri
    @okta_provider_uri ||= validated_env_var('OKTA_PROVIDER_URI')
  end

  def okta_scope
    "openid profile email"
  end

  def okta_redirect_uri
    @oidc_redirect_uri ||= 'http://localhost:3000/authn-oidc/okta/cucumber/authenticate'
  end
end

World(AuthnOidcHelper)
