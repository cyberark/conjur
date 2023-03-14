# frozen_string_literal: true

require 'spec_helper'

describe EdgeController, :type => :request do
  let(:account) { "rspec" }

  before do
    Slosilo["authn:#{account}"] ||= Slosilo::Key.new
  end
  let(:current_user) { Role.find_or_create(role_id: "#{account}:host:edge/edge") }
  let(:update_slosilo_key_url) do
    "/edge/slosilo_key/#{account}"
  end

  let(:token_auth_header) do
    bearer_token = Slosilo["authn:#{account}"].signed_token(current_user.login)
    token_auth_str =
      "Token token=\"#{Base64.strict_encode64(bearer_token.to_json)}\""
    { 'HTTP_AUTHORIZATION' => token_auth_str }
  end

  context "slosilo key in DB" do
    it "Slosilo key equals to key in DB" do
      Role.create(role_id: "#{account}:group:edge/edge-hosts")
      Role.create(role_id: "#{account}:host:edge/edge")
      RoleMembership.create(role_id: "#{account}:group:edge/edge-hosts", member_id: "#{account}:host:edge/edge", admin_option: false, ownership:false)

      get(update_slosilo_key_url, env: token_auth_header)
      expect(response.code).to eq("200")

      key = Slosilo["authn:#{account}"]
      private_key = key.to_der.unpack("H*")[0]
      fingerprint = key.fingerprint

      expected = {"slosiloKeys" => [{"privateKey"=> private_key,"fingerprint"=>fingerprint}]}
      response_json = JSON.parse(response.body)
      expect(response_json).to include(expected)
    end
  end

end