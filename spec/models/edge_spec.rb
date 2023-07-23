# frozen_string_literal: true

require 'spec_helper'

describe "EdgeObject" do
  let(:identifier) {"1234"}
  let(:account) { "rspec" }
  let(:request) { double(ip: "1.1.1.1") }
  let(:host_id) {"#{account}:host:edge/edge-#{identifier}/edge-host-#{identifier}"}
  let(:installer_host_id) {"#{account}:host:edge/edge-installer-#{identifier}/edge-installer-host-#{identifier}"}

  before do
    Edge.new_edge(id: identifier, name: "Edgy")
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
end
