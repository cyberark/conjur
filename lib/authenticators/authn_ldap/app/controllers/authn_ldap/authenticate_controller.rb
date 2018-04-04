require_dependency 'authn_ldap/application_controller'

module AuthnLdap
  class AuthenticateController < ApplicationController
    def authenticate

      login    = params[:login]
      password = request.body.read
      token    = authenticator.auth(login, password)

      if token
        render json: token.to_json

      else
        render json: { status: 401 }
      end

    end

    private

    def authenticator
      @authenticator ||= AuthnLdap::Authenticator.new(
        ldap_server: AuthnLdap::LdapServer.new(
          uri:     ENV['LDAP_URI'],
          base:    ENV['LDAP_BASE'],
          bind_dn: ENV['LDAP_BINDDN'],
          bind_pw: ENV['LDAP_BINDPW']
        ),
        ldap_filter: ENV['LDAP_FILTER']
      )
    end

  end
end
