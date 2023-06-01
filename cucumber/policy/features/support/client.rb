# frozen_string_literal: true

require 'delegate'
require_relative 'rest_client_wrapper'

# Client is a rest client for the Conjur API designed for Cucumber tests.
# Instances for specific users are created with `Client.for`, which instantiates
# `Client` with an authentication token.  Tests can then call API endpoints
# methods without worrying about authentication.
#
# All these methods should be together.
# :reek:TooManyMethods
class Client
  ADMIN_PASSWORD = 'SEcret12!!!!'
  ACCOUNT = ENV['CONJUR_ACCOUNT'] || 'cucumber'
  APPLIANCE_URL =  ENV['CONJUR_APPLIANCE_URL'] || "http://conjur#{ENV['TEST_ENV_NUMBER']}"

  class User
    def initialize(user_type, id)
      unless %w[user host].include?(user_type)
        raise 'User type must be "user" or "host"'
      end

      @user_type = user_type
      @id = id
    end

    def self.admin
      User.new("user", "admin")
    end

    def ==(other)
      login == other.login
    end

    def login
      ([@user_type, @id] - ["user"]).join('/')
    end

    def role
      [@user_type, @id].join(":")
    end
  end

  class << self

    def for(user_type, id)
      user = User.new(user_type, id)
      for_role(user)
    end

    def auth_header(token)
      { Authorization:  %Q(Token token="#{token}") }
    end

    private

    def for_role(user)
      user_admin = User.admin
      admin_key = fetch_admin_api_key
      admin_token = create_token(user_admin, admin_key)

      return new(admin_token) if user == user_admin

      role_api_key = create_api_key(user, admin_token)
      token = create_token(user, role_api_key)
      new(token)
    end

    def create_token(user, role_api_key)
      url = "#{APPLIANCE_URL}/authn/#{ACCOUNT}/#{CGI.escape(user.login)}" \
        '/authenticate'
      RestClient.post(url, role_api_key, 'Accept-Encoding': 'Base64').body
    end

    # Use an admin token to create an API key for another role.
    def create_api_key(user, admin_token)
      url = "#{APPLIANCE_URL}/authn/#{ACCOUNT}/api_key"
      headers = auth_header(admin_token).merge(params: { role: user.role })
      RestClient::Resource.new(url).put("", headers)
    end

    def fetch_admin_api_key
      url = "#{APPLIANCE_URL}/authn/#{ACCOUNT}/login"
      RestClient::Resource.new(url, "admin", ADMIN_PASSWORD).get
    end
  end

  def initialize(token)
    @token = token
  end

  # Policy methods
  #

  # Introducing a value object doesn't make sense yet.
  # :reek:DataClump
  def load_policy(id:, policy:)
    resource(uri("policies", "policy", id)).put(policy, auth_header)
  end

  # :reek:DataClump
  def update_policy(id:, policy:)
    resource(uri("policies", "policy", id)).patch(policy, auth_header)
  end

  # :reek:DataClump
  def replace_policy(id:, policy:)
    resource(uri("policies", "policy", id)).post(policy, auth_header)
  end

  # Resource methods
  #
  def fetch_resource(kind:, id:)
    resource(uri('resources', kind, id)).get(auth_header)
  end

  def fetch_secret(id:)
    resource(uri('secrets', 'variable', id)).get(auth_header)
  end

  def add_secret(id:, value:)
    resource(uri('secrets', 'variable', id)).post(value, auth_header)
  end

  def fetch_roles(kind:, id:)
    resource(uri('roles', kind, id)).get(auth_header)
  end

  def fetch_authenticators
    resource(uri('authn-oidc', 'providers')).get
  end

  def fetch_public_keys(username:)
    resource(uri('public_keys', 'user', username)).get(auth_header)
  end

  def fetch_roles_with_privilege(kind:, id:, privilege:)
    resource(uri('resources', kind, id)).get(
      auth_header.merge(
        params: { permitted_roles: true, privilege: privilege }
      )
    )
  end

  private

  def auth_header
    @auth_header ||= self.class.auth_header(@token)
  end

  # A value object or injecting APPLIANCE_URL/ACCOUNT would be overkill.
  # :reek:UtilityFunction
  def uri(root, kind, id = nil)
    uri = "#{APPLIANCE_URL}/#{root}/#{ACCOUNT}/#{kind}"
    return uri unless id

    "#{uri}/#{CGI.escape(id)}"
  end

  # A URI value object would be overkill.
  # :reek:UtilityFunction
  def resource(uri_)
    RestClientWrapper.new(
      RestClient::Resource.new(
        uri_, 'Content-Type' => 'application/json'
      )
    )
  end
end
