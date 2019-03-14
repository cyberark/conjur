# frozen_string_literal: true

require 'spec_helper'

describe ::CA::SSH::CertificateRequest do
  describe '#validate' do
    let(:params) do
      {
        public_key: public_key,
        principals: principals
      }
    end

    let(:role) do
      double("role", 
        account: "rspec", 
        kind: "user", 
        identifier: "alice",
        resource: role_resource) 
    end

    let(:role_resource) { double("role_resource", annotations: [] )}

    # Generated with `ssh-keygen -t rsa`
    let(:public_key) { "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAklOUpkDHrfHY17SbrmTIpNLTGK9Tjom/BWDSUGPl+nafzlHDTYW7hdI4yZ5ew18JH4JW9jbhUFrviQzM7xlELEVf4h9lFX5QVkbPppSwg0cda3Pbv7kOdJ/MTyBlWXFCR+HAo3FXRitBqxiX1nKhXpHAZsMciLq8V6RjsNAQwdsdMFvSlVK/7XAt3FaoJoAsncM1Q9x5+3V0Ww68/eIFmb1zuUFljQJKprrX88XypNDvjYNby6vw/Pb0rwert/EnmZ+AW4OZPnTPI89ZPmVMLuayrD2cE86Z/il8b+gw3r3+1nKatmIkjn2so1d01QraTlMqVSsbxNrRFi9wrf+M7Q==" }
    let(:principals) { "alice" }

    let(:certificate_request) { ::CA::SSH::CertificateRequest.build(role: role, params: params) }

    context "when all of the inputs are valid" do
      it "returns without error" do
        expect(certificate_request).to be_a(::CA::SSH::CertificateRequest)
      end
    end
  end
end
