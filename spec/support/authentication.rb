shared_context "authenticate Basic" do
  let(:params) { {} }
  let(:basic_auth_header) { 
    basic = Base64.strict_encode64([login, password].join(':'))
    "Basic #{basic}"
  }
  before {
    request.env['HTTP_AUTHORIZATION'] = basic_auth_header
  }
end

shared_context "authenticate Token" do
  let(:params) { {} }
  let(:bearer_token) { Slosilo[:own].signed_token(login) }
  let(:token_auth_header) { "Token token=\"#{Base64.strict_encode64 bearer_token.to_json}\"" }
  before {
    request.env['HTTP_AUTHORIZATION'] = token_auth_header
  }
end

shared_context "create user" do
  let(:the_user) { 
    AuthnUser.create(login: login, password: password)
  }
  before {
    the_user
  }
end
