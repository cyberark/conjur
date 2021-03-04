require 'spec_helper'

describe Audit::Event::Check do

  let(:user) { double('my-user', id: 'rspec:user:my_user') }
  let(:resource) { double('my-resource', id: 'rspec:variable:my_var') }
  let(:privilege) { 'execute' }
  let(:role) { double('my-host', id: 'rspec:host:my_host') }
  let(:client_ip) { 'my-client-ip' }
  let(:success) { true }
  let(:operation) { 'check' }

  subject do
    Audit::Event::Check.new(
      user: user,
      resource: resource,
      privilege: privilege,
      role: role,
      client_ip: client_ip,
      operation: operation,
      success: success
    )
  end

  context 'when successful' do
    it 'produces the expected message' do
      expect(subject.message).to eq(
        'rspec:user:my_user checked if rspec:host:my_host can execute ' \
        'rspec:variable:my_var (success)'
      )
    end

    it 'uses the INFO log level' do
      expect(subject.severity).to eq(Syslog::LOG_INFO)
    end

    it 'renders to string correctly' do
      expect(subject.to_s).to eq(
        'rspec:user:my_user checked if rspec:host:my_host can execute ' \
        'rspec:variable:my_var (success)'
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
        'rspec:user:my_user checked if rspec:host:my_host can execute ' \
        'rspec:variable:my_var (failure)'
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
    let(:resource) { 'rspec:variable:non_existing_var' }

    it 'produces the expected message' do
      expect(subject.message).to eq(
                                   'rspec:user:my_user checked if rspec:host:my_host can execute ' \
        'rspec:variable:non_existing_var (failure)'
                                 )
    end

    it_behaves_like 'structured data includes client IP address'
  end

  context 'when the role does not exist and a failure occurs' do
    let(:success) { false }
    let(:role) { 'rspec:host:my_non_existing_host' }

    it 'produces the expected message' do
      expect(subject.message).to eq(
                                   'rspec:user:my_user checked if rspec:host:my_non_existing_host can execute ' \
        'rspec:variable:my_var (failure)'
                                 )
    end

    it_behaves_like 'structured data includes client IP address'
  end
end
