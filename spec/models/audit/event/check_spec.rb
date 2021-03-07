require 'spec_helper'

describe Audit::Event::Check do

  let(:user) { double('my-user', id: 'rspec:user:my_user') }
  let(:resource_id)  {'rspec:variable:my_var'}
  let(:privilege) { 'execute' }
  let(:role_id) { 'rspec:host:my_host' }
  let(:client_ip) { 'my-client-ip' }
  let(:success) { true }
  let(:operation) { 'check' }
  let(:error_message) { nil }

  subject do
    Audit::Event::Check.new(
      user: user,
      resource_id: resource_id,
      privilege: privilege,
      role_id: role_id,
      client_ip: client_ip,
      operation: operation,
      success: success,
      error_message: error_message
    )
  end

  context 'when successful' do
    it 'produces the expected message' do
      expect(subject.message).to eq(
        'rspec:user:my_user successfully checked if rspec:host:my_host can execute ' \
        'rspec:variable:my_var '
                                 )
    end

    it 'uses the INFO log level' do
      expect(subject.severity).to eq(Syslog::LOG_INFO)
    end

    it 'renders to string correctly' do
      expect(subject.to_s).to eq(
        'rspec:user:my_user successfully checked if rspec:host:my_host can execute ' \
        'rspec:variable:my_var '
                              )
    end

    it 'produces the expected action_sd' do
      expect(subject.action_sd).to eq({:"action@43868"=>{:operation=>"check", :result=>"success"}})
    end

    it_behaves_like 'structured data includes client IP address'
  end

  context 'when a failure occurs' do
    let(:success) { false }

    it 'produces the expected message' do
      expect(subject.message).to eq(
        'rspec:user:my_user failed to check if rspec:host:my_host can execute ' \
        'rspec:variable:my_var '
                                 )
    end

    it 'uses the WARNING log level' do
      expect(subject.severity).to eq(Syslog::LOG_WARNING)
    end

    it 'produces the expected action_sd' do
      expect(subject.action_sd).to eq({:"action@43868"=>{:operation=>"check", :result=>"failure"}})
    end

    it_behaves_like 'structured data includes client IP address'
  end

  context 'when the resource does not exist and a failure occurs' do
    let(:success) { false }
    let(:resource_id) { 'rspec:variable:non_existing_var' }
    let(:error_message) { 'Variable \'non-existing-var\' not found in account \'CyberArk\''}

    it 'produces the expected message' do
      expect(subject.message).to eq(
        'rspec:user:my_user failed to check if rspec:host:my_host can execute ' \
        'rspec:variable:non_existing_var : Variable \'non-existing-var\' not found in account \'CyberArk\''
                                 )
    end

    it_behaves_like 'structured data includes client IP address'
  end

  context 'when the role does not exist and a failure occurs' do
    let(:success) { false }
    let(:role_id) { 'rspec:host:my_non_existing_host' }
    let(:error_message) { 'Forbidden' }

    it 'produces the expected message' do
      expect(subject.message).to eq(
        'rspec:user:my_user failed to check if rspec:host:my_non_existing_host can execute ' \
        'rspec:variable:my_var : Forbidden'
                                 )
    end

    it_behaves_like 'structured data includes client IP address'
  end
end
