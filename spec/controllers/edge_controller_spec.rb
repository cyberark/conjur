# frozen_string_literal: true

require 'spec_helper'

describe EdgeController, :type => :request do
  let(:account) { "rspec" }
  let(:host_id) {"#{account}:host:edge/edge-host-1234"}
  let(:other_host_id) {"#{account}:host:data/other"}
  let(:admin_user_id) {"#{account}:user:admin_user"}

  let(:log_output) { StringIO.new }
  let(:logger) { Logger.new(log_output) }

  before do
    init_slosilo_keys(account)
    @current_user = Role.find_or_create(role_id: host_id)
    @other_user = Role.find_or_create(role_id: other_host_id)
    @admin_user = Role.find_or_create(role_id: admin_user_id)
  end

  let(:update_slosilo_keys_url) do
    "/edge/slosilo_keys/#{account}"
  end

  let(:get_hosts) do
    "/edge/hosts/#{account}"
  end

  let(:list_edges) do
    "/edge/edges/#{account}"
  end

  let(:report_edge) do
    "/edge/data/#{account}"
  end


  let(:init_prev_key) do
    Slosilo[token_id(account, "host", "previous")] ||= Slosilo::Key.new
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
      encoded_api_key = @result['hosts'][0]['api_key']
      encoded_salt = @result['hosts'][0]['salt']
      salt = Base64.strict_decode64(encoded_salt)
      test_api_key =  Base64.strict_encode64(Cryptography.hmac_api_key(@other_user.credentials.api_key, salt))
      expect(test_api_key).to eq(encoded_api_key)
    end
  end

  context "Visibility" do
    before do
      Role.create(role_id: "#{account}:group:edge/edge-hosts")
      RoleMembership.create(role_id: "#{account}:group:edge/edge-hosts", member_id: host_id, admin_option: false, ownership:false)
      Edge.new_edge(name: "edgy", id: 1234, version: "latest", platform: "podman", installation_date: Time.at(111111111), last_sync: Time.at(222222222))
      EdgeController.logger = logger
      Role.create(role_id: "#{account}:group:Conjur_Cloud_Admins")
      RoleMembership.create(role_id: "#{account}:group:Conjur_Cloud_Admins", member_id: admin_user_id, admin_option: false, ownership:false)
    end

    it "Report install data endpoint works" do
      edge_details = '{"installation_date": 111111111}'
      post("#{report_edge}?data_type=install", env: token_auth_header(role: @current_user, is_user: false)
                                                      .merge({'RAW_POST_DATA': edge_details})
                                                      .merge({'CONTENT_TYPE': 'application/json'}))

      expect(response.code).to eq("204")
      db_edgy = Edge.where(name: "edgy").first
      expect(db_edgy.installation_date.to_i).to eq(111111111)
    end

    it "Report ongoing data endpoint works" do
      edge_details = '{"edge_statistics": {"last_synch_time": 222222222, "cycle_requests": {
                        "get_secret":123,"apikey_authenticate": 234, "jwt_authenticate":345, "redirect": 456}},
                      "edge_version": "latest", "edge_container_type": "podman"}'
      post("#{report_edge}?data_type=ongoing", env: token_auth_header(role: @current_user, is_user: false)
                               .merge({'RAW_POST_DATA': edge_details})
                               .merge({'CONTENT_TYPE': 'application/json'}))

      expect(response.code).to eq("204")
      db_edgy = Edge.where(name: "edgy").first
      expect(db_edgy.last_sync.to_i).to eq(222222222)
      expect(db_edgy.version).to eq("latest")
      expect(db_edgy.platform).to eq("podman")
      output = log_output.string
      expect(output).to include("EdgeTelemetry")
      %w[edgy 123 234 345 456].each {|arg| expect(output).to include(arg)}
    end

    it "List endpoint works" do
      get(list_edges, env: token_auth_header(role: @admin_user, is_user: true))

      expect(response.code).to eq("200")
      resp = JSON.parse(response.body)
      expect(resp.size).to eq(1)
      expect(resp[0]['last_sync']).to eq(222222222)
      expect(resp[0]['version']).to eq("latest")
      expect(resp[0]['platform']).to eq("podman")
    end

    it "Reported data appears on list" do
      edge_details = '{"edge_statistics": {"last_synch_time": 222222222}, "edge_version": "latest", "edge_container_type": "podman"}'
      post("#{report_edge}?data_type=ongoing", env: token_auth_header(role: @current_user, is_user: false)
                               .merge({'RAW_POST_DATA': edge_details})
                               .merge({'CONTENT_TYPE': 'application/json'}))
      expect(response.code).to eq("204")

      get(list_edges, env: token_auth_header(role: @admin_user, is_user: true))
      expect(response.code).to eq("200")
      resp = JSON.parse(response.body)
      expect(resp.size).to eq(1)
      expect(resp[0]['last_sync']).to eq(222222222)
      expect(resp[0]['version']).to eq("latest")
      expect(resp[0]['platform']).to eq("podman")
    end

    it "Report invalid data" do
      missing_optional = '{"edge_statistics": {"last_synch_time": 222222222}, "edge_version": "latest"}'
      post("#{report_edge}?data_type=ongoing", env: token_auth_header(role: @current_user, is_user: false)
                               .merge({'RAW_POST_DATA': missing_optional})
                               .merge({'CONTENT_TYPE': 'application/json'}))
      expect(response.code).to eq("204")

      missing_required = '{"edge_statistics": {}, "edge_version": "latest", "edge_container_type": "podman"}'
      post("#{report_edge}?data_type=ongoing", env: token_auth_header(role: @current_user, is_user: false)
                               .merge({'RAW_POST_DATA': missing_required})
                               .merge({'CONTENT_TYPE': 'application/json'}))
      expect(response.code).to eq("422")
    end
  end
end
