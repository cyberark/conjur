require_relative '../../gems/conjur-rack/lib/conjur/rack/authenticator.rb'

account = "cucumber"
user_id = "user:yoav"
password = "FruitBucket12#"
apiKey = "wow"
Pact.provider_states_for "Conjur API java" do

  set_up() do
    path = File.join Rails.root,  'spec','services_consumers','rsa.pem'
    rsa = OpenSSL::PKey::RSA.new File.read "#{path}"
    init_slosilo_key_static_value(account, rsa)
    Role.find_or_create(role_id: "#{account}:#{user_id}")
    role = Role["#{account}:#{user_id}"]
    token = token_auth_header(role: role, account: account)
    puts "Token is - #{token}"

    role.password = password
    role.save
    role.api_key
    role.credentials.static_api_key (apiKey)
    role.credentials.save
     end

  provider_state "Authenticate this" do
    set_up do
      allow_any_instance_of(TokenFactory).to receive(:signed_token).and_return("{\"protected\": \"eyJhbGciOiJjb25qdXIub3JnL3Nsb3NpbG8vdjIiLCJraWQiOiJmZTZhY2E2MmQ3ZTY4YWY0MjJkODAxMDA3ZjcyMTkwZDlmNWNhNjQ0NTkxMDg3OTRlNWIwNzFiZjg4YTNhZDFhIn0=\"," +
                                                                 "\"payload\": \"eyJzdWIiOiJ5b2F2IiwiZXhwIjoxNjg3MDc3OTA5LCJpYXQiOjE2ODcwNzc0Mjl9\"," +
                                                                 "\"signature\": \"oRzP7jIjw7VG1-h9M7_iDZOjvlYQrggNHLq71zu9kjpSahGSRUbveegFuycm3ReLrDX2M-OuJpq1L7-sEpLYI1FcJ4in2HJ5UVPnBI3MOT8YJyEqyW86pF_dRoCYEwzQteHLT_rR5bLcFn9rAFqqfWFtXcNRF9Q3dbL-gr6ZTrXjxNOrMlFv3qfpb8XtXldtkRFWZKoIiUOq0MBOLgCyo4GOVWJt0s9zvVoG5fYNQj4WYIuC_080qfr5jZsVm5i2TtzfIIffkuZvkCzDHKMv8hkqAdOSJ3k4tbN9C8BXn_owSMXO5LQbJVsdPsGEh6UkY9xmcAOHn2mH03fc6kMblGpO75GvEdELt1uwrQt04f4hCEK0x1wEE7r4kCnm0BDO\"" +
                                                                 "}")

      # allow_any_instance_of(TokenFactory).to receive(:signed_token).and_return("wow")

      # allow_any_instance_of(AuthenticateController).to receive(:authenticate).and_return(token)
    end
  end

  provider_state "Login" do
    set_up do

    end
  end

  provider_state "get secret" do
    set_up do
      # Your set up code goes here
    end
  end

end
