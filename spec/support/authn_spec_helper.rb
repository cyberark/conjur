shared_context "authn setup" do
  let(:input) do
    ::Authentication::AuthenticatorInput.new(
      authenticator_name: 'authn',
      service_id:         'service',
      account:            'account',
      username:           'username',
      credentials:        'creds',
      client_ip:          '127.0.0.1',
      request:            nil
    )
  end

  let(:role_cls) { double("Role") }
  def role_cls
    double('Role').tap do |role|
      allow(role).to(
        receive(:roleid_from_username)
      ).and_return(
        "account:user:username"
      )
    end
  end

  let(:credentials_cls) { double("Credentials") }
  def credentials_cls
    double('Credentials').tap do |creds|
      allow(creds).to receive(:[]).and_return(creds)
      allow(creds).to receive(:authenticate).and_return(true)
      allow(creds).to receive(:api_key).and_return('a valid api key')
    end
  end

  let(:non_existing_role_credentials) { double("Credentials") }
  def non_existing_role_credentials
    double('Credentials').tap do |creds|
      allow(creds).to receive(:[]).and_return(nil)
    end
  end


  let(:invalid_api_key_credentials) { double("Credentials") }
  def invalid_api_key_credentials
    double('Credentials').tap do |creds|
      allow(creds).to receive(:[]).and_return(creds)
      allow(creds).to receive(:valid_api_key?).and_return(false)
    end
  end

  let(:valid_api_key_credentials) { double("Credentials") }
  def valid_api_key_credentials
    double('Credentials').tap do |creds|
      allow(creds).to receive(:[]).and_return(creds)
      allow(creds).to receive(:valid_api_key?).and_return(true)
    end
  end
end
