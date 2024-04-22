# frozen_string_literal: true
require 'spec_helper'

describe EdgeConfigurationController, :type => :request do
  let(:account) { "rspec" }
  let(:identifier) {"1234"}
  let(:edge_name) {"edgy"}
  let(:admin_user_id) {"#{account}:user:admin_user"}
  let(:other_user_id) {"#{account}:user:other"}
  let(:edge_host_id) {"#{account}:host:edge/edge-1234/edge-host-1234"}
  let(:edge_host_id_2) {"#{account}:host:edge/edge-2/edge-host-2"}

  let(:get_roles) do
    "/agent/get-role/#{account}"
  end

  let(:get_edge_info) do
    "/agents/#{account}/#{identifier}/info"
  end

  before do
    init_slosilo_keys(account)
    @other_user = Role.find_or_create(role_id: other_user_id)
    @admin_user = Role.find_or_create(role_id: admin_user_id)
    @edge_host = Role.find_or_create(role_id: edge_host_id)
    @edge_host_2 = Role.find_or_create(role_id: edge_host_id_2)
  end

  context "Agent Edge Info" do
    before do
      Role.create(role_id: "#{account}:group:Conjur_Cloud_Admins")
      RoleMembership.create(role_id: "#{account}:group:Conjur_Cloud_Admins", member_id: admin_user_id, admin_option: false, ownership:false)
      Role.create(role_id: "#{account}:group:Conjur_Cloud_Users")
      RoleMembership.create(role_id: "#{account}:group:Conjur_Cloud_Users", member_id: other_user_id, admin_option: false, ownership:false)
      Role.create(role_id: "#{account}:group:edge/edge-hosts")
      RoleMembership.create(role_id: "#{account}:group:edge/edge-hosts", member_id: edge_host_id, admin_option: false, ownership:false)
      Edge.new_edge(name: "#{edge_name}", id: "#{identifier}", version: "1.1.1", platform: "podman", installation_date: Time.at(111111111), last_sync: Time.at(222222222))
      RoleMembership.create(role_id: "#{account}:group:edge/edge-hosts", member_id: edge_host_id_2, admin_option: false, ownership:false)
      #Edge.new_edge(name: "edgy2", id: "2", version: "1.1.1", platform: "podman", installation_date: Time.at(111111111), last_sync: Time.at(222222222))
    end

    it "Edge host get role" do
      get("#{get_roles}", env: token_auth_header(role: @edge_host, is_user: true ))
      expect(response.code).to eq("200")
      json_body = JSON.parse(response.body)
      expect(json_body).to include("is_Conjur_Cloud_Admins"=> false, "is_Conjur_Cloud_Users"=> false, "is_edge_hosts"=> true)
    end

    it "Conjur Admin user get role" do
      get("#{get_roles}", env: token_auth_header(role: @admin_user, is_user: true ))
      expect(response.code).to eq("200")
      json_body = JSON.parse(response.body)
      expect(json_body).to include("is_Conjur_Cloud_Admins"=> true , "is_Conjur_Cloud_Users"=> false, "is_edge_hosts"=> false )
    end

    it "Conjur user get role" do
      get("#{get_roles}", env: token_auth_header(role: @other_user, is_user: true ))
      expect(response.code).to eq("200")
      json_body = JSON.parse(response.body)
      expect(json_body).to include("is_Conjur_Cloud_Admins"=> false , "is_Conjur_Cloud_Users"=> true , "is_edge_hosts"=> false )
    end

    it "Agent Edge get info" do
      get("#{get_edge_info}", env: token_auth_header(role: @edge_host, is_user: false ))
      expect(response.code).to eq("200")
      json_body = JSON.parse(response.body)
      expect(json_body).to include("id"=> "1234" , "name"=> "edgy" )
    end

    it "Agent Edge get info failed 403 different edge user" do
      get("#{get_edge_info}", env: token_auth_header(role: @edge_host_2, is_user: false ))
      expect(response.code).to eq("403")
    end

    it "Agent Edge get info failed 403 for non edge user" do
      get("#{get_edge_info}", env: token_auth_header(role: @other_user, is_user: true ))
      expect(response.code).to eq("403")
    end

    it "Agent Edge get info failed 403 for non edge admin user" do
      get("#{get_edge_info}", env: token_auth_header(role: @admin_user, is_user: true ))
      expect(response.code).to eq("403")
    end

    it "Agent Edge get info failed 404 for non exist edge" do
      get( "/agents/#{account}/2/info", env: token_auth_header(role: @edge_host_2, is_user: false ))
      expect(response.code).to eq("404")
    end
  end
end

