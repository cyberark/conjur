require_dependency 'authn_ldap/application_controller'

module AuthnLdap
  class AuthenticateController < ApplicationController
    def authenticate
      token    = authenticator.auth(
        login: params[:login],
        password: request.body.read,
        account: params[:account] || ENV['CONJUR_ACCOUNT'],
        service_id: params[:service_id]
      )
      raise 'LDAP authentication failed' unless token
      render json: token.to_json

      # AuthenticatorNotEnabled, ServiceNotDefined, NotAuthorizedInConjur and
      # unknown errors are all handled the same way
    rescue => e
      render status: 401, json: error_json(e.message)
    end

    private

    def error_json(msg)
      {status: 'error', msg: msg}
    end

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
