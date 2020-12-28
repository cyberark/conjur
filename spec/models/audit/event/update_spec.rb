require 'spec_helper'

describe Audit::Event::Update do

  let(:user) { double('my-user', id: 'rspec:user:my_user') }
  let(:resource) do
    double(
      'my-resource',
      id: 'rspec:variable:my_var',
      # This is required for the Audit::Resource subject creation
      pk_hash: { resource_id: 'rspec:variable:my_var' }
    )
  end
  let(:client_ip) { 'my-client-ip' }
  let(:success) { true }
  let(:error_message) { nil }
  let(:operation) { 'update' }

  subject do
    Audit::Event::Update.new(
      user: user,
      resource: resource,
      client_ip: client_ip,
      success: success,
      operation: operation,
      error_message: error_message
    )
  end

  context 'when successful' do
    it 'produces the expected message' do
      expect(subject.message).to eq(
        'rspec:user:my_user updated rspec:variable:my_var'
      )
    end

    it 'uses the INFO log level' do
      expect(subject.severity).to eq(Syslog::LOG_INFO)
    end

    it 'renders to string correctly' do
      expect(subject.to_s).to eq(
        'rspec:user:my_user updated rspec:variable:my_var'
      )
    end

    it 'produces the expected action_sd' do
      expect(subject.action_sd).to eq({:"action@43868"=>{:operation=>"update", :result=>"success"}})
    end

    it_behaves_like 'structured data includes client IP address'
  end

  context 'when a failure occurs' do
    let(:success) { false }
    let(:error_message) { 'not permitted' }

    it 'produces the expected message' do
      expect(subject.message).to eq(
        'rspec:user:my_user tried to update rspec:variable:my_var: not permitted'
      )
    end

    it 'uses the WARNING log level' do
      expect(subject.severity).to eq(Syslog::LOG_WARNING)
    end

    it 'produces the expected action_sd' do
      expect(subject.action_sd).to eq({:"action@43868"=>{:operation=>"update", :result=>"failure"}})
    end

    it_behaves_like 'structured data includes client IP address'
  end
end
