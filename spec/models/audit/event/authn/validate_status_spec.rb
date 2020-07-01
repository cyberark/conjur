require 'spec_helper'

describe Audit::Event::Authn::ValidateStatus do
  let(:role_id) { 'rspec:user:my_user' }
  let(:authenticator_name) { 'my-authenticator'}
  let(:service) { double('my-service', resource_id: 'rspec:webservice:my-service') }
  let(:client_ip) { 'my-client-ip' }
  let(:success) { true }
  let(:error_message) { nil }

  subject do
    Audit::Event::Authn::ValidateStatus.new(
      role_id: role_id,
      authenticator_name: authenticator_name,
      service: service,
      success: success,
      client_ip: client_ip,
      error_message: error_message
    )
  end

  context 'when successful' do
    it 'produces the expected message' do
      expect(subject.message).to eq(
        'rspec:user:my_user successfully validated status for authenticator ' \
        'my-authenticator service rspec:webservice:my-service'
      )
    end

    it 'uses the INFO log level' do
      expect(subject.severity).to eq(Syslog::LOG_INFO)
    end

    it 'renders to string correctly' do
      expect(subject.to_s).to eq(
        'rspec:user:my_user successfully validated status for authenticator ' \
        'my-authenticator service rspec:webservice:my-service'
      )
    end

    it_behaves_like 'structured data includes client IP address'
  end

  context 'when a failure occurs' do
    let(:success) { false }
    let(:error_message) { 'invalid user' }

    it 'produces the expected message' do
      expect(subject.message).to eq(
        'rspec:user:my_user failed to validate status for authenticator ' \
        'my-authenticator service rspec:webservice:my-service: invalid user'
      )
    end

    it 'uses the WARNING log level' do
      expect(subject.severity).to eq(Syslog::LOG_WARNING)
    end

    it_behaves_like 'structured data includes client IP address'
  end
end
