require 'spec_helper'

describe Audit::Event::Fetch do

  let(:user) { double('my-user', id: 'rspec:user:my_user') }
  let(:resource) { double('my-resource', id: 'rspec:variable:my_var') }
  let(:client_ip) { 'my-client-ip' }
  let(:success) { true }
  let(:version) { 1 }
  let(:error_message) { nil }


  subject do
    Audit::Event::Fetch.new(
      user: user,
      resource: resource,
      version: version,
      client_ip: client_ip,
      success: success,
      error_message: error_message
    )
  end

  context 'when successful' do
    it 'produces the expected message' do
      expect(subject.message).to eq(
        'rspec:user:my_user fetched version 1 of rspec:variable:my_var'
      )
    end

    it 'uses the INFO log level' do
      expect(subject.severity).to eq(Syslog::LOG_INFO)
    end

    it 'renders to string correctly' do
      expect(subject.to_s).to eq(
        'rspec:user:my_user fetched version 1 of rspec:variable:my_var'
      )
    end

    it_behaves_like 'structured data includes client IP address'
  end

  context 'when a failure occurs' do
    let(:success) { false }
    let(:error_message) { 'not permitted' }

    it 'produces the expected message' do
      expect(subject.message).to eq(
        'rspec:user:my_user tried to fetch version 1 of ' \
        'rspec:variable:my_var: not permitted'
      )
    end

    it 'uses the WARNING log level' do
      expect(subject.severity).to eq(Syslog::LOG_WARNING)
    end

    it_behaves_like 'structured data includes client IP address'
  end
end
