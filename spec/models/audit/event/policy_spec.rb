require 'spec_helper'

describe Audit::Event::Policy do

  let(:user) { double('my-user', id: 'rspec:user:my_user') }
  let(:resource) do
    Audit::Subject::Resource.new(
      resource_id: 'rspec:variable:my_var'
    )
  end
  let(:client_ip) { 'my-client-ip' }
  let(:operation) { '' }
  let(:policy_version) do
    double(
      'the-policy-version',
      id: 'rspec:policy:my_policy', 
      client_ip: client_ip,
      version: 1,
      role: user
    )
  end
  let(:error_message) { nil }

  subject do
    Audit::Event::Policy.new(
      subject: resource,
      operation: operation,
      policy_version: policy_version,
      error_message: error_message
    )
  end

  context "when operation is 'add'" do
    let(:operation) { :add }

    it 'produces the expected message' do
      expect(subject.message).to eq(
        'rspec:user:my_user added resource rspec:variable:my_var'
      )
    end

    it 'uses the INFO log level' do
      expect(subject.severity).to eq(Syslog::LOG_NOTICE)
    end

    it 'renders to string correctly' do
      expect(subject.to_s).to eq(
        'rspec:user:my_user added resource rspec:variable:my_var'
      )
    end

    it 'contains the user field' do
      expect(subject.structured_data).to match(hash_including({
        Audit::SDID::AUTH => { user: user.id }
      }))
    end

    it_behaves_like 'structured data includes client IP address'
  end

  context "when operation is 'remove'" do
    let(:operation) { :remove }

    it 'renders to string correctly' do
      expect(subject.to_s).to eq(
        'rspec:user:my_user removed resource rspec:variable:my_var'
      )
    end

    it_behaves_like 'structured data includes client IP address'
  end

  context "when operation is 'change'" do
    let(:operation) { :change }

    it 'renders to string correctly' do
      expect(subject.to_s).to eq(
        'rspec:user:my_user changed resource rspec:variable:my_var'
      )
    end

    it_behaves_like 'structured data includes client IP address'
  end

  context "when operation fails" do
    let(:error_message) { 'Unauthorized to load policy' }
    it 'marks operation as failure' do
      expect(subject.structured_data).to match(hash_including({
              Audit::SDID::ACTION => { operation: operation, result: 'failure' }
          }))
    end

    it 'produces the error message' do
      expect(subject.message).to include(error_message)
    end
  end
end
