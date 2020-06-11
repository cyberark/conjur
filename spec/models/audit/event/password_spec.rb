require 'spec_helper'

describe Audit::Event::Password do
  let(:role_id) { 'rspec:user:my_user' }
  let(:user) { double('The User', id: role_id) }
  let(:success) { true }
  let(:error_message) { nil }

  subject do
    Audit::Event::Password.new(
      user: user,
      success: success,
      error_message: error_message
    )
  end

  context 'when successful' do
    it 'produces the expected message' do
      expect(subject.message)
        .to eq("rspec:user:my_user successfully changed their password")
    end

    it 'uses the INFO log level' do
      expect(subject.severity).to eq(Syslog::LOG_INFO)
    end

    it 'renders to string correctly' do
      expect(subject.to_s).to eq('rspec:user:my_user successfully changed their password')
    end
  end

  context 'when a failure occurs' do
    let(:success) { false }
    let(:error_message) { 'invalid password' }

    it 'produces the expected message' do
      expect(subject.message)
        .to eq("rspec:user:my_user failed to change their password: invalid password")
    end

    it 'uses the WARNING log level' do
      expect(subject.severity).to eq(Syslog::LOG_WARNING)
    end
  end
end
