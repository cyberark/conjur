require 'spec_helper'

describe Audit::Event::Authn::InjectClientCert do
  let(:role_id) { 'rspec:host:my_host' }
  let(:authenticator_name) { 'my-authenticator'}
  let(:service) { double('my-service', resource_id: 'rspec:webservice:my-service') }
  let(:client_ip) { 'my-client-ip' }
  let(:success) { true }
  let(:error_message) { nil }

  subject do
    Audit::Event::Authn::InjectClientCert.new(
      role_id: role_id,
      authenticator_name: authenticator_name,
      service: service,
      client_ip: client_ip,
      success: success,
      error_message: error_message
    )
  end

  context 'when successful' do
    it 'produces the expected message' do
      expect(subject.message).to eq(
        'rspec:host:my_host successfully injected client certificate with ' \
        'authenticator my-authenticator service rspec:webservice:my-service'
      )
    end

    it 'uses the INFO log level' do
      expect(subject.severity).to eq(Syslog::LOG_INFO)
    end

    it 'renders to string correctly' do
      expect(subject.to_s).to eq(
        'rspec:host:my_host successfully injected client certificate with ' \
        'authenticator my-authenticator service rspec:webservice:my-service'
      )
    end

    it_behaves_like 'structured data includes client IP address'
  end

  context 'when a failure occurs' do
    let(:success) { false }
    let(:error_message) { 'invalid host' }

    it 'produces the expected message' do
      expect(subject.message).to eq(
        'rspec:host:my_host failed to inject client certificate with ' \
        'authenticator my-authenticator service rspec:webservice:my-service: invalid host'
      )
    end

    it 'uses the WARNING log level' do
      expect(subject.severity).to eq(Syslog::LOG_WARNING)
    end

    it_behaves_like 'structured data includes client IP address'
  end
end
