require 'spec_helper'

describe Audit::Event::Authn do
  subject(:event) do
    Audit::Event::Authn.new \
      role: the_user,
      authenticator_name: 'authn-test',
      service: service
  end

  describe '#success' do
    it 'sends an info message' do
      expect(logger).to receive(:log).with \
        Logger::Severity::INFO,
        an_object_having_attributes(
          message: matching(/successfully authenticated/),
          message_id: 'authn',
          facility: Syslog::LOG_AUTHPRIV,
          structured_data: {
            'subject@43868': { role: "rspec:user:alice" },
            'auth@43868': {
              authenticator: 'authn-test',
              service: 'rspec:webservice:test'
            },
            'action@43868': {
              operation: 'authenticate',
              result: 'success'
            }
          }
        ), 'conjur'
      event.success.log_to logger
    end
  end

  describe 'failure' do
    it 'sends a warning message' do
      expect(logger).to receive(:log).with \
        Logger::Severity::WARN,
        an_object_having_attributes(
          message: matching(/failed to authenticate.*: test error/),
          message_id: 'authn',
          facility: Syslog::LOG_AUTHPRIV,
          structured_data: {
            'subject@43868': { role: "rspec:user:alice" },
            'auth@43868': {
              authenticator: 'authn-test',
              service: 'rspec:webservice:test'
            },
            'action@43868': {
              operation: 'authenticate',
              result: 'failure'
            }
          }
        ), 'conjur'
      event.failure('test error').log_to logger
    end
  end

  context "with no webservice parameter" do
    let(:service) { nil }

    it 'does not include service in metadata nor message' do
      expect(event.success.message).not_to include 'service'
      expect(event.structured_data[:'auth@43868']).not_to have_key :service
    end
  end

  let(:logger) { instance_double Logger }
  let(:service) { double(Resource, id: 'rspec:webservice:test') }
  include_context("create user") { let(:login) { 'alice' } }
end
