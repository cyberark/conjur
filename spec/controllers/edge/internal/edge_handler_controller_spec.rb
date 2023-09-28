# frozen_string_literal: true

require 'spec_helper'

describe EdgeHandlerController, :type => :request do
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
      edge_details = '{"edge_statistics": {"last_synch_time": 1692633684386, "cycle_requests": {
                        "get_secret":123,"apikey_authenticate": 234, "jwt_authenticate":345, "redirect": 456}},
                      "edge_version": "1.1.1", "edge_container_type": "podman"}'
      ENV["TENANT_ID"] = "44da7894-4cc5-4bcd-b37c-316ad40ec8c6"
      post("#{report_edge}?data_type=ongoing", env: token_auth_header(role: @current_user, is_user: false)
                               .merge({'RAW_POST_DATA': edge_details})
                               .merge({'CONTENT_TYPE': 'application/json'}))

      expect(response.code).to eq("204")
      db_edgy = Edge.where(name: "edgy").first
      expect(db_edgy.last_sync.to_i).to eq(1692633684386)
      expect(db_edgy.version).to eq("1.1.1")
      expect(db_edgy.platform).to eq("podman")
      output = log_output.string
      expect(output).to include("EdgeTelemetry")
      %w[edgy 123 234 345 456 44da7894-4cc5-4bcd-b37c-316ad40ec8c6 2023-08-21].each {|arg| expect(output).to include(arg)}
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
