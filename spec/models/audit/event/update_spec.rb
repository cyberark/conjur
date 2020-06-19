require 'spec_helper'

describe Audit::Event::Update do

  let(:user) { double('my-user', id: 'rspec:user:my_user') }
  let(:resource) { double('my-resource', id: 'rspec:variable:my_var') }
  
  let(:success) { true }
  let(:error_message) { nil }


  subject do
    Audit::Event::Update.new(
      user: user,
      resource: resource,
      success: success,
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
  end
end
