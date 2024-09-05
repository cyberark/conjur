# frozen_string_literal: true

require 'spec_helper'

describe "EdgeObject" do
  let(:identifier) {"1234"}
  let(:account) { "rspec" }
  let(:request) { double(ip: "1.1.1.1") }
  let(:host_id) {"#{account}:host:edge/edge-#{identifier}/edge-host-#{identifier}"}
  let(:installer_host_id) {"#{account}:host:edge/edge-installer-#{identifier}/edge-installer-host-#{identifier}"}

  before do
    Edge.new_edge(max_edges: 10, id: identifier, name: "Edgy")
    Role.find_or_create(role_id: host_id)
    Role.find_or_create(role_id: installer_host_id)
  end

  subject { Edge[identifier] }

  context "Edge installation" do
    it "Generate Edge script" do
      authenticate_mock = double(Authentication::Authenticate)
      subject_mock = subject
      allow(subject_mock).to receive(:new_authenticate).and_return(authenticate_mock)
      expect(authenticate_mock).to receive(:call).with(anything) do |input|
        expect(input[:authenticator_input][:username]).to eq(Role.username_from_roleid(installer_host_id))
        expect(input[:authenticator_input][:credentials]).to eq(Role[installer_host_id].api_key)
      end

      expect{ subject_mock.get_installer_token(account, request) }.to_not raise_error
    end
  end

  context "Edge max validation" do
    subject{ EdgeCreationController.new }

    it "missing max edge" do
      expect { Edge.new_edge(name: "edgy2", id: 2, version: "1.1.1", platform: "podman", installation_date: Time.at(111111111), last_sync: Time.at(222222222)) }.to raise_error(ArgumentError)
    end
  end

  context "get_name_by_hostname" do
    it "logs KeyError and returns empty string" do
      hostname = "test-hostname"
      edge_mock = double("Edge")
      allow(Edge).to receive(:get_by_hostname).with(hostname).and_return(edge_mock)
      allow(edge_mock).to receive(:[]).with(:name).and_raise(KeyError, "key not found: :name")

      result = Edge.get_name_by_hostname(hostname)
      expect(result).to eq("")
    end

    it "returns the name when present" do
      hostname = "test-hostname"
      edge_mock = double("Edge", name: "Edgy")
      allow(Edge).to receive(:get_by_hostname).with(hostname).and_return(edge_mock)
      allow(edge_mock).to receive(:[]).with(:name).and_return("Edgy")

      result = Edge.get_name_by_hostname(hostname)
      expect(result).to eq("Edgy")
    end
  end
end
