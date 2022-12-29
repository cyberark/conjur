require 'spec_helper'

describe Audit::Event::Memberships do
  let(:user_id) { 'rspec:user:my_user' }
  let(:client_ip) { 'my-client-ip' }
  let(:list_param) { { "limit"=> "1000" } }
  let(:success) { true }
  let(:error_message) { nil }


  subject do
    Audit::Event::Memberships.new(
      user_id: user_id,
      client_ip: client_ip,
      subject: list_param,
      success: success,
      error_message: error_message
    )
  end

  context 'when successful' do
    it 'produces the expected message' do
      expect(subject.message).to eq(
                                   'rspec:user:my_user successfully listed memberships with parameters: {"limit"=>"1000"}'
                                 )
    end

    it 'uses the INFO log level' do
      expect(subject.severity).to eq(Syslog::LOG_INFO)
    end

    it 'renders to string correctly' do
      expect(subject.to_s).to eq(
                                'rspec:user:my_user successfully listed memberships with parameters: {"limit"=>"1000"}'
                              )
    end

    it 'contains the user field' do
      expect(subject.structured_data).to match(hash_including({
                                                                Audit::SDID::AUTH => { user: user_id }
                                                              }))
    end

    it 'contains the ip field' do
      expect(subject.structured_data).to match(hash_including({
                                                                Audit::SDID::CLIENT => { ip: client_ip }
                                                              }))
    end

    it 'produces the expected action_sd' do
      expect(subject.action_sd).to eq({ "action@43868": { operation: "list", result: "success" } })
    end

    it_behaves_like 'structured data includes client IP address'
  end

  context 'when a failure occurs' do
    let(:success) { false }

    it 'produces the expected message' do
      expect(subject.message).to eq(
                                   'rspec:user:my_user failed to list memberships with parameters: {"limit"=>"1000"}'
                                 )
    end

    it 'uses the WARNING log level' do
      expect(subject.severity).to eq(Syslog::LOG_WARNING)
    end

    it 'produces the expected action_sd' do
      expect(subject.action_sd).to eq({ "action@43868": { operation: "list", result: "failure" } })
    end

    it_behaves_like 'structured data includes client IP address'
  end



end