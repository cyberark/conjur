# frozen_string_literal: true

require 'spec_helper'

describe EdgeVisibilityController, :type => :request do
  let(:account) { "rspec" }
  let(:host_id) {"#{account}:host:edge/edge-1234/edge-host-1234"}
  let(:admin_user_id) {"#{account}:user:admin_user"}

  let(:log_output) { StringIO.new }
  let(:logger) { Logger.new(log_output) }

  before do
    init_slosilo_keys(account)
    @current_user = Role.find_or_create(role_id: host_id)
    @admin_user = Role.find_or_create(role_id: admin_user_id)
  end

  let(:list_edges) do
    "/edge/#{account}"
  end

  let(:report_edge) do
    "/edge/data/#{account}"
  end

  context "Visibility" do
    before do
      Role.create(role_id: "#{account}:group:edge/edge-hosts")
      RoleMembership.create(role_id: "#{account}:group:edge/edge-hosts", member_id: host_id, admin_option: false, ownership:false)
      Edge.new_edge(name: "edgy", id: 1234, version: "1.1.1", platform: "podman", installation_date: Time.at(111111111), last_sync: Time.at(222222222))
      EdgeHandlerController.logger = logger
      Role.create(role_id: "#{account}:group:Conjur_Cloud_Admins")
      RoleMembership.create(role_id: "#{account}:group:Conjur_Cloud_Admins", member_id: admin_user_id, admin_option: false, ownership:false)
    end

    it "List endpoint works" do
      # Add some more edges
      Edge.new_edge(name: "hedge", id: 7777)
      Edge.new_edge(name: "grudge", id: 8888)
      Edge.new_edge(name: "fudge", id: 9999)

      get(list_edges, env: token_auth_header(role: @admin_user, is_user: true))

      expect(response.code).to eq("200")
      resp = JSON.parse(response.body)
      expect(resp.size).to eq(4)
      expect(resp[0]['name']).to eq('edgy')
      expect(resp[0]['last_sync']).to eq(222222222)
      expect(resp[0]['version']).to eq("1.1.1")
      expect(resp[0]['platform']).to eq("podman")

      expect(resp[1]['name']).to eq('fudge')
      expect(resp[2]['name']).to eq('grudge')
      expect(resp[3]['name']).to eq('hedge')
    end

    it "Reported data appears on list" do
      edge_details = '{"edge_statistics": {"last_synch_time": 222222222}, "edge_version": "1.1.1", "edge_container_type": "podman"}'
      post("#{report_edge}?data_type=ongoing", env: token_auth_header(role: @current_user, is_user: false)
                               .merge({'RAW_POST_DATA': edge_details})
                               .merge({'CONTENT_TYPE': 'application/json'}))
      expect(response.code).to eq("204")

      get(list_edges, env: token_auth_header(role: @admin_user, is_user: true))
      expect(response.code).to eq("200")
      resp = JSON.parse(response.body)
      expect(resp.size).to eq(1)
      expect(resp[0]['last_sync']).to eq(222222222)
      expect(resp[0]['version']).to eq("1.1.1")
      expect(resp[0]['platform']).to eq("podman")
    end

    it "Report invalid data" do
      missing_optional = '{"edge_statistics": {"last_synch_time": 222222222}, "edge_version": "1.1.1"}'
      post("#{report_edge}?data_type=ongoing", env: token_auth_header(role: @current_user, is_user: false)
                               .merge({'RAW_POST_DATA': missing_optional})
                               .merge({'CONTENT_TYPE': 'application/json'}))
      expect(response.code).to eq("204")

      missing_required = '{"edge_statistics": {}, "edge_version": "1.1.1", "edge_container_type": "podman"}'
      post("#{report_edge}?data_type=ongoing", env: token_auth_header(role: @current_user, is_user: false)
                               .merge({'RAW_POST_DATA': missing_required})
                               .merge({'CONTENT_TYPE': 'application/json'}))
      expect(response.code).to eq("422")
    end

    it "Report works even without installation" do
      edgy = Edge["1234"]
      edgy.update(installation_date: nil)

      edge_details = '{"edge_statistics": {"last_synch_time": 222222222}, "edge_version": "1.1.1", "edge_container_type": "podman"}'
      post("#{report_edge}?data_type=ongoing", env: token_auth_header(role: @current_user, is_user: false)
                                                      .merge({'RAW_POST_DATA': edge_details})
                                                      .merge({'CONTENT_TYPE': 'application/json'}))
      expect(response.code).to eq("204")
      edgy = Edge["1234"]
      expect(edgy.installation_date).to eq(Time.at(-1))
    end
  end
end
