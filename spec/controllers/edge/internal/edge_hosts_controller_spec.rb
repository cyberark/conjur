require 'spec_helper'

describe EdgeHostsController, :type => :request do
  let(:account) { "rspec" }
  let(:host_id) {"#{account}:host:edge/edge-1234/edge-host-1234"}
  let(:other_host_id) {"#{account}:host:data/other"}
  let(:no_apikey_host_id) {"#{account}:host:data/noapikey"}
  let(:admin_user) { Role.find_or_create(role_id: 'rspec:user:admin') }

  let(:get_hosts) do
    "/edge/hosts/#{account}"
  end

  before do
    init_slosilo_keys(account)

    @current_user = create_host(host_id, admin_user)
    @other_user = create_host(other_host_id, admin_user)
    @no_apikey_host = create_host_without_apikey(no_apikey_host_id, admin_user)
  end

  context "Host" do
    it "Check HMAC" do
      #add edge-hosts to edge/edge-hosts group
      Role.create(role_id: "#{account}:group:edge/edge-hosts")
      RoleMembership.create(role_id: "#{account}:group:edge/edge-hosts", member_id: host_id, admin_option: false, ownership:false)
      get(get_hosts, env: token_auth_header(role: @current_user, is_user: false))
      expect(response.code).to eq("200")
      expect(response).to be_ok
      expect(response.body).to include("api_key".strip)
      expect(response.body).to include("salt".strip)
      @result = JSON.parse(response.body)
      encoded_api_key = @result['hosts'][1]['api_key']
      encoded_salt = @result['hosts'][1]['salt']
      salt = Base64.strict_decode64(encoded_salt)
      test_api_key =  Base64.strict_encode64(Cryptography.hmac_api_key(@other_user.credentials.api_key, salt))
      expect(test_api_key).to eq(encoded_api_key)
      expect("").to eq(@result['hosts'][0]['api_key'])
      expect("").to eq(@result['hosts'][0]['salt'])
    end
  end
end