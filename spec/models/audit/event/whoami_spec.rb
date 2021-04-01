require 'spec_helper'

describe Audit::Event::Whoami do
  let(:my_role_id) { 'rspec:user:my_user' }
  let(:role) { double('Role', role_id: my_role_id) }
  let(:client_ip) { 'my-client-ip' }
  let(:success) { true }
  let(:version) { 1 }

  subject do
    Audit::Event::Whoami.new(
      client_ip: client_ip,
      role: role,
      success: success
    )
  end

  context 'when successful' do
    it 'produces the expected message' do
      expect(subject.message).to eq(
        'rspec:user:my_user checked its identity using whoami'
      )
    end

    it 'uses the INFO log level' do
      expect(subject.severity).to eq(Syslog::LOG_INFO)
    end

    it 'produces the expected action_sd' do
      expect(subject.action_sd).to eq({ "action@43868": { operation: "check", result: "success" } })
    end

    it_behaves_like 'structured data includes client IP address'
  end
end
