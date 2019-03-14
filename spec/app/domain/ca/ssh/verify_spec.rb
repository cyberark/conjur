# frozen_string_literal: true

require 'spec_helper'

describe ::CA::SSH::Verify do
  describe '#validate' do
    let(:certificate_request) do
      ::CA::CertificateRequest.new(kind: kind, params: params, role: role)
    end

    let(:webservice) { ::CA::Webservice.new(resource: ca_resource) }

    let(:kind) { :ssh }
    let(:params) do
      {
        public_key: public_key,
        principals: principals
      }
    end
    let(:role) { double("role") }
    let(:webservice) { double("webservice") }
    let(:env) { double("env") }

    let(:public_key) { double("public_key") }
    let(:principals) { double("principals") }

    subject { ::CA::SSH::Verify.new(webservice: webservice, env: env).(certificate_request: certificate_request) }

    context "when all of the inputs are valid" do
      it "returns without error" do
        subject
      end
    end
  end
end