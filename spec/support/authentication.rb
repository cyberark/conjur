# frozen_string_literal: true

shared_context "authenticate Basic" do
  let(:params) { { account: account, authenticator: authenticator } }
  let(:basic_auth_header) {
    basic = Base64.strict_encode64([login, basic_password].join(':'))
    "Basic #{basic}"
  }
  before {
    request.env['HTTP_AUTHORIZATION'] = basic_auth_header
  }
end

shared_context "authenticate Token" do
  let(:params) { { account: account  } }
  let(:bearer_token) { Slosilo["authn:rspec"].signed_token(login) }
  let(:token_auth_header) { "Token token=\"#{Base64.strict_encode64 bearer_token.to_json}\"" }
  before {
    request.env['HTTP_AUTHORIZATION'] = token_auth_header
  }
end

shared_context "create user" do
  def create_user(login)
    Role.create(role_id: "rspec:user:#{login}").tap do |role|
      options = { role: role }
      options[:password] = password if defined?(password) && password
      Credentials.create(options)
      role.reload
    end
  end

  let(:login) { "default-login" }
  # 'let!' always runs before the example; 'let' is lazily evaluated.
  let!(:the_user) { 
    create_user(login)
  }
  let(:api_key) { the_user.credentials.api_key }
end
