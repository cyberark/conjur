# frozen_string_literal: true

require 'spec_helper'

describe EdgeSlosiloKeysController, :type => :request do
  let(:account) { "rspec" }
  let(:host_id) {"#{account}:host:edge/edge-1234/edge-host-1234"}

  let(:init_prev_key) do
    Slosilo[token_id(account, "host", "previous")] ||= Slosilo::Key.new
  end

  let(:update_slosilo_keys_url) do
    "/edge/slosilo_keys/#{account}"
  end

  before do
    init_slosilo_keys(account)
    @current_user = Role.find_or_create(role_id: host_id)
  end

  def send_request_with_correct_role
    #add edge-hosts to edge/edge-hosts group
    Role.create(role_id: "#{account}:group:edge/edge-hosts")
    RoleMembership.create(role_id: "#{account}:group:edge/edge-hosts", member_id: host_id, admin_option: false, ownership:false)
    get(update_slosilo_keys_url, env: token_auth_header(role: @current_user, is_user: false))
    expect(response.code).to eq("200")
  end

  context "slosilo keys in DB" do
    it "Host and Role are correct, previous key is empty" do
      send_request_with_correct_role
      #get the Slosilo key from DB
      key = token_key(account, "host")
      private_key = key.to_der.unpack("H*")[0]
      fingerprint = key.fingerprint

      expected = {"slosiloKeys" => [{"privateKey"=> private_key,"fingerprint"=>fingerprint}], "previousSlosiloKeys" => []}
      response_json = JSON.parse(response.body)
      expect(response_json).to eq(expected)
    end

    it "Host and Role are correct, previous key exist in db" do
      init_prev_key
      send_request_with_correct_role
      #get the Slosilo key from DB
      key = token_key(account, "host")
      private_key = key.to_der.unpack("H*")[0]
      fingerprint = key.fingerprint
      #get prev Slosilo key from DB
      prev_key = token_key(account, "host", "previous")
      prev_private_key = prev_key.to_der.unpack("H*")[0]
      prev_fingerprint = prev_key.fingerprint

      expected = {"slosiloKeys" => [{"privateKey"=> private_key,"fingerprint"=>fingerprint}], "previousSlosiloKeys" => [{"privateKey"=> prev_private_key,"fingerprint"=>prev_fingerprint}]}
      response_json = JSON.parse(response.body)
      expect(response_json).to eq(expected)
    end

    it "Host is Edge but no Role exists at all" do
      #get the Slosilo key the URL request
      get(update_slosilo_keys_url, env: token_auth_header(role: @current_user, is_user: false))
      expect(response.code).to eq("403")
    end

    it "Host is Edge but the host is member in wrong role" do
      #add edge-hosts to edge2/edge-hosts group
      Role.create(role_id: "#{account}:group:edge2/edge-hosts")
      RoleMembership.create(role_id: "#{account}:group:edge2/edge-hosts", member_id: host_id, admin_option: false, ownership:false)

      #get the Slosilo key the URL request
      get(update_slosilo_keys_url, env: token_auth_header(role: @current_user, is_user: false))
      expect(response.code).to eq("403")
    end
  end
end