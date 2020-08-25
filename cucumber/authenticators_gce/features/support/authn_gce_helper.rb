require 'jwt'

module AuthnGceHelper
  include AuthenticatorHelpers

  ACCOUNT = 'cucumber'

  def gce_instance_name
    @gce_machine_name ||= validated_env_var('GCE_INSTANCE_NAME')
  end

  def gce_service_account_email
    @gce_service_account_email ||= validated_env_var('GCE_SERVICE_ACCOUNT_EMAIL')
  end

  def gce_project_id
    @gce_project_id ||= validated_env_var('GCE_PROJECT_ID')
  end

  def gce_service_account_id
    @gce_service_account_id ||= validated_env_var('GCE_SERVICE_ACCOUNT_ID')
  end


  def authenticate_gce_token(account:, gce_token:)
    path_uri = "#{conjur_hostname}/authn-gce/#{account}/authenticate"

    payload = {}
    payload["jwt"] = gce_token

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

  payload, headers = { data: data }, { kid: jwk.kid }

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

def gce_identity_access_token(token_type)
  case token_type
  when :valid
    @gce_identity_token = gce_token_valid
  when :standard_format
    @gce_identity_token = gce_token_standard_format
  when :invalid_audience
    @gce_identity_token = gce_token_invalid_audience
  when :non_existing_host
    @gce_identity_token = gce_token_non_existing_host
  when :non_rooted_host
    @gce_identity_token = gce_token_non_rooted_host
  when :non_existing_account
    @gce_identity_token = gce_token_non_existing_account
  when :user_audience
    @gce_identity_token = gce_token_user_audience
  end

  @gce_identity_token
end

def gce_token_valid
  @gce_token_valid ||= read_token_file("gce_token_valid")
end

def gce_token_standard_format
  @gce_token_standard_format ||= read_token_file("gce_token_standard_format")
end

def gce_token_invalid_audience
  @gce_token_invalid_audience ||= read_token_file("gce_token_invalid_audience")
end

def gce_token_non_existing_host
  @gce_token_non_existing_host ||= read_token_file("gce_token_non_existing_host")
end

def gce_token_non_rooted_host
  @gce_token_non_rooted_host ||= read_token_file("gce_token_non_rooted_host")
end

def gce_token_non_existing_account
  @gce_token_non_existing_account ||= read_token_file("gce_token_non_existing_account")
end

def gce_token_user_audience
  @gce_token_user_audience ||= read_token_file("gce_token_user")
end

def read_token_file(token_file_name)
  token = nil
  file = nil
  path = File.join('./ci/authn-gce/tokens', token_file_name)

  unless File.exist?(path)
    raise "Token file: '#{path}' not found."
  end

  begin
    file = File.open(path)
    token = file.read
  rescue => e
    raise "Error reading token file: #{path}, error: #{e.inspect}"
  ensure
    file.close if file
  end
  token
end

World(AuthnGceHelper)
