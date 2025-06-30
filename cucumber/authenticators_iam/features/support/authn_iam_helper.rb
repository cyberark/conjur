# frozen_string_literal: true

require 'aws-sigv4'
require 'aws-sdk-core'

def iam_identity_access_token
  region = ENV['AWS_REGION'] || 'us-east-1'

  access_key_id = ENV['AWS_ACCESS_KEY_ID']
  secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']

  raise "AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY must be set" if access_key_id.nil? || secret_access_key.nil?

  @iam_access_token = Aws::Sigv4::Signer.new(
    service: 'sts',
    region: region,
    credentials_provider: Aws::Credentials.new(access_key_id, secret_access_key)
  ).sign_request(
    http_method: 'GET',
    url: "https://sts.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15"
  ).headers
end
def authenticate_iam_token(username)
  user_id_part = username.gsub("/", "%2F")
  path_uri = "#{conjur_hostname}/authn-iam/prod/cucumber/#{user_id_part}/authenticate"

  payload = @iam_access_token.to_json

  headers["Content-Type"] = "application/json"

  post(path_uri, payload)
end
