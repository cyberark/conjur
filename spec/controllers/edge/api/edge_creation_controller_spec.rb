# frozen_string_literal: true
require 'spec_helper'

describe EdgeCreationController, :type => :request do
  let(:account) { "rspec" }
  let(:host_id) {"#{account}:host:edge/edge-1234/edge-host-1234"}
  let(:admin_user_id) {"#{account}:user:admin_user"}
  let(:other_host_id) {"#{account}:host:data/other"}

  let(:edge_creds) do
    "/edge/edge-creds/#{account}"
  end

  before do
    init_slosilo_keys(account)
    @current_user = Role.find_or_create(role_id: host_id)
    @other_user = Role.find_or_create(role_id: other_host_id)
    @admin_user = Role.find_or_create(role_id: admin_user_id)
  end

  context "Edge name validation" do
    subject{ EdgeCreationController.new }

    it "Edge names are validated" do
      expect { subject.send(:validate_name, "Edgy") }.to_not raise_error
      expect { subject.send(:validate_name, "Edgy_05") }.to_not raise_error
      expect { subject.send(:validate_name, "a") }.to_not raise_error

      expect { subject.send(:validate_name, nil) }.to raise_error
      expect { subject.send(:validate_name, "") }.to raise_error
      expect { subject.send(:validate_name, "Edgy!") }.to raise_error
      expect { subject.send(:validate_name, "SuperExtremelyLongEdgeName11111111111111111111111111111111111111111111111111") }.to raise_error
    end
  end

  context "Edge id validation" do
    subject{ EdgeCreationController.new }

    it "Edge id are validated" do
      expect { subject.send(:validate_uuid_format, "54dbe71c-e82a-455d-b90d-8bbe0a7b4963") }.to_not raise_error
      expect { subject.send(:validate_uuid_format, nil) }.to_not raise_error
      expect { subject.send(:validate_uuid_format, "") }.to_not raise_error
      expect { subject.send(:validate_uuid_format, "54d@#71c-e82a-455db90d8bbe0a7b4963") }.to raise_error
      expect { subject.send(:validate_uuid_format, "54dbe71ce82a-455db90d8bbe0a7b4963") }.to raise_error
      expect { subject.send(:validate_uuid_format, "54dbe71c-e82a-455db90d8bbe0a7b4963") }.to raise_error

    end
  end

  context "Installation" do
    before do
      Role.create(role_id: "#{account}:group:edge/edge-hosts")
      RoleMembership.create(role_id: "#{account}:group:edge/edge-hosts", member_id: host_id, admin_option: false, ownership:false)
      Edge.new_edge(name: "edgy", id: 1234, version: "1.1.1", platform: "podman", installation_date: Time.at(111111111), last_sync: Time.at(222222222))
      Role.create(role_id: "#{account}:group:Conjur_Cloud_Admins")
      RoleMembership.create(role_id: "#{account}:group:Conjur_Cloud_Admins", member_id: admin_user_id, admin_option: false, ownership:false)
    end

    it "Generate script error cases" do
      #Missing edge
      get("#{edge_creds}/non-existent", env: token_auth_header(role: @admin_user, is_user: true))
      expect(response.code).to eq("404")

      #Not admin
      get("#{edge_creds}/edgy", env: token_auth_header(role: @other_user, is_user: true))
      expect(response.code).to eq("403")

      #Wrong account
      get("/edge/edge-creds/tomato/edgy", env: token_auth_header(role: @admin_user, is_user: true))
      expect(response.code).to eq("403")
    end
  end
end

