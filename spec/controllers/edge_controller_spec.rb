# frozen_string_literal: true

require 'spec_helper'

describe EdgeController, :type => :request do
  let(:account) { "rspec" }
  let(:host_id) {"#{account}:host:edge/edge"}
  let(:other_host_id) {"#{account}:host:data/other"}

  before do
    init_slosilo_keys(account)
    @current_user = Role.find_or_create(role_id: host_id)
    @other_user = Role.find_or_create(role_id: other_host_id)
  end

  let(:update_slosilo_keys_url) do
    "/edge/slosilo_keys/#{account}"
  end

  let(:get_hosts) do
    "/edge/hosts/#{account}"
  end

  let(:token_auth_header) do
    bearer_token = token_key(account, "host").signed_token(@current_user.login)
    token_auth_str =
      "Token token=\"#{Base64.strict_encode64(bearer_token.to_json)}\""
    { 'HTTP_AUTHORIZATION' => token_auth_str }
  end

  context "slosilo keys in DB" do
    it "Slosilo keys equals to key in DB, Host and Role are correct" do
      #add edge-hosts to edge/edge-hosts group
      Role.create(role_id: "#{account}:group:edge/edge-hosts")
      RoleMembership.create(role_id: "#{account}:group:edge/edge-hosts", member_id: host_id, admin_option: false, ownership:false)

      #get the Slosilo key the URL request
      get(update_slosilo_keys_url, env: token_auth_header)
      expect(response.code).to eq("200")

      #get the Slosilo key from DB
      key = token_key(account, "host")
      private_key = key.to_der.unpack("H*")[0]
      fingerprint = key.fingerprint

      expected = {"slosiloKeys" => [{"privateKey"=> private_key,"fingerprint"=>fingerprint}]}
      response_json = JSON.parse(response.body)
      expect(response_json).to include(expected)
    end

    it "Host is Edge but no Role exists at all" do
      #get the Slosilo key the URL request
      get(update_slosilo_keys_url, env: token_auth_header)
      expect(response.code).to eq("403")
    end

    it "Host is Edge but the host is member in wrong role" do
      #add edge-hosts to edge2/edge-hosts group
      Role.create(role_id: "#{account}:group:edge2/edge-hosts")
      RoleMembership.create(role_id: "#{account}:group:edge2/edge-hosts", member_id: host_id, admin_option: false, ownership:false)

      #get the Slosilo key the URL request
      get(update_slosilo_keys_url, env: token_auth_header)
      expect(response.code).to eq("403")
    end
  end

  context "Host" do
    it "Check HMAC" do
      #add edge-hosts to edge/edge-hosts group
      Role.create(role_id: "#{account}:group:edge/edge-hosts")
      RoleMembership.create(role_id: "#{account}:group:edge/edge-hosts", member_id: host_id, admin_option: false, ownership:false)
      get(get_hosts, env: token_auth_header)
      expect(response.code).to eq("200")
      expect(response).to be_ok
      expect(response.body).to include("api_key".strip)
      expect(response.body).to include("salt".strip)
      @result = JSON.parse(response.body)
      encoded_api_key = @result['hosts'][0]['api_key']
      encoded_salt = @result['hosts'][0]['salt']
      salt = Base64.strict_decode64(encoded_salt)
      test_api_key =  Base64.strict_encode64(Cryptography.hmac_api_key(@other_user.credentials.api_key, salt))
      expect(test_api_key).to eq(encoded_api_key)
    end
  end
end