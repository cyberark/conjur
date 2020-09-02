# frozen_string_literal: true

require 'jwt'

module AuthnGcpHelper
  include AuthenticatorHelpers

  ACCOUNT = 'cucumber'

  def gcp_instance_name
    @gcp_instance_name ||= validated_env_var('GCP_INSTANCE_NAME')
  end

  def gcp_service_account_email
    @gcp_service_account_email ||= validated_env_var('GCP_SERVICE_ACCOUNT_EMAIL')
  end

  def gcp_project_id
    @gcp_project_id ||= validated_env_var('GCP_PROJECT_ID')
  end

  def gcp_service_account_id
    @gcp_service_account_id ||= validated_env_var('GCP_SERVICE_ACCOUNT_ID')
  end

  def authenticate_gcp_token(account:, gcp_token:)
    path_uri = "#{conjur_hostname}/authn-gcp/#{account}/authenticate"

    payload = {}
    payload["jwt"] = gcp_token

    post(path_uri, payload)
  end
end

# generates a self signed token
def self_signed_token
  # generate key to sign the token
  jwk = JWT::JWK.new(OpenSSL::PKey::RSA.new(2048))

  # define token expiration
  exp = Time.now.to_i + 4 * 3600

  # token claims
  data = {
    iss: 'self-signed',
    aud: 'my_service',
    sub: 'foo_bar',
    exp: exp
  }

  payload = { data: data }
  headers = { kid: jwk.kid }

  # issue a decoded signed token
  JWT.encode(payload, jwk.keypair, 'RS512', headers)
end

# generates a self signed token with no kid in token header
def no_kid_self_signed_token
  rsa_private = OpenSSL::PKey::RSA.generate 2048

  # define token expiration
  exp = Time.now.to_i + 4 * 3600

  # token claims
  exp_payload = {
    iss: 'self-signed',
    aud: 'my_service',
    sub: 'foo_bar',
    exp: exp
  }

  # issue decoded signed token
  JWT.encode exp_payload, rsa_private, 'RS256'
end

def gcp_identity_access_token(token_type)
  case token_type
  when :valid
    @gcp_identity_token = gcp_token_valid
  when :standard_format
    @gcp_identity_token = gcp_token_standard_format
  when :invalid_audience
    @gcp_identity_token = gcp_token_invalid_audience
  when :non_existing_host
    @gcp_identity_token = gcp_token_non_existing_host
  when :non_rooted_host
    @gcp_identity_token = gcp_token_non_rooted_host
  when :non_existing_account
    @gcp_identity_token = gcp_token_non_existing_account
  when :user_audience
    @gcp_identity_token = gcp_token_user_audience
  else
    raise "Invalid token type given: #{token_type}"
  end

  @gcp_identity_token
end

def gcp_token_valid
  @gcp_token_valid ||= read_token_file("gcp_token_valid")
end

def gcp_token_standard_format
  @gcp_token_standard_format ||= read_token_file("gcp_token_standard_format")
end

def gcp_token_invalid_audience
  @gcp_token_invalid_audience ||= read_token_file("gcp_token_invalid_audience")
end

def gcp_token_non_existing_host
  @gcp_token_non_existing_host ||= read_token_file("gcp_token_non_existing_host")
end

def gcp_token_non_rooted_host
  @gcp_token_non_rooted_host ||= read_token_file("gcp_token_non_rooted_host")
end

def gcp_token_non_existing_account
  @gcp_token_non_existing_account ||= read_token_file("gcp_token_non_existing_account")
end

def gcp_token_user_audience
  @gcp_token_user_audience ||= read_token_file("gcp_token_user")
end

def read_token_file(token_file_name)
  token = nil
  file = nil
  path = File.join('./ci/authn-gcp/tokens', token_file_name)

  unless File.exist?(path)
    raise "Token file: '#{path}' not found."
  end

  begin
    file = File.open(path)
    token = file.read
  rescue => e
    raise "Error reading token file: #{path}, error: #{e.inspect}"
  ensure
    file&.close
  end
  token
end

World(AuthnGcpHelper)
