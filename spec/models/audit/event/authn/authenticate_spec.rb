require 'spec_helper'

describe Audit::Event::Authn::Authenticate do
  let(:role_id) { 'rspec:user:my_user' }
  let(:role) { double('my-role', id: role_id) }
  let(:authenticator_name) { 'my-authenticator'}
  let(:service) { double('my-service', resource_id: 'rspec:webservice:my-service') }
  let(:success) { true }
  let(:error_message) { nil }

  subject do
    Audit::Event::Authn::Authenticate.new(
      role: role,
      authenticator_name: authenticator_name,
      service: service,
      success: success,
      error_message: error_message
    )
  end

  context 'when successful' do
    it 'produces the expected message' do
      expect(subject.message).to eq(
        'rspec:user:my_user successfully authenticated with authenticator ' \
        'my-authenticator service rspec:webservice:my-service'
      )
    end

    it 'uses the INFO log level' do
      expect(subject.severity).to eq(Syslog::LOG_INFO)
    end

    it 'renders to string correctly' do
      expect(subject.to_s).to eq(
        'rspec:user:my_user successfully authenticated with authenticator ' \
        'my-authenticator service rspec:webservice:my-service'
      )
    end
  end

  context 'when a failure occurs' do
    let(:success) { false }
    let(:error_message) { 'invalid authentication' }

    it 'produces the expected message' do
      expect(subject.message).to eq(
        'rspec:user:my_user failed to authenticate with authenticator ' \
        'my-authenticator service rspec:webservice:my-service: invalid authentication'
      )
    end

    it 'uses the WARNING log level' do
      expect(subject.severity).to eq(Syslog::LOG_WARNING)
    end
  end
end
