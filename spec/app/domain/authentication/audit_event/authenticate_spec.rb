# frozen_string_literal: true

require 'spec_helper'

describe Audit::Event::Authn::Authenticate do
  subject(:event) do
    Audit::Event::Authn::Authenticate.new(
      role: the_user,
      authenticator_name: 'authn-test',
      service: service,
      success: true
    )
  end

  context 'when successful' do
    it 'sends an info message' do
      # TODO: These two things should be tested separately
      audit_logger = Audit::Log::SyslogAdapter.new(ruby_logger)

      expect(ruby_logger).to receive(:log).with(
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
        ),
        'conjur'
      )
      audit_logger.log(event)
    end
  end

  describe 'on failure' do
    subject(:event) do
      Audit::Event::Authn::Authenticate.new(
        role: the_user,
        authenticator_name: 'authn-test',
        service: service,
        success: false,
        error_message: 'test error'
      )
    end

    it 'sends a warning message' do
      # TODO: These two things should be tested separately
      ruby_log = ruby_logger
      audit_logger = Audit::Log::SyslogAdapter.new(ruby_log)

      expect(ruby_log).to receive(:log).with(
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
        ),
        'conjur'
      )
      audit_logger.log(event)
    end
  end

  context "with no webservice parameter" do
    let(:service) { nil }

    it 'does not include service in metadata nor message' do
      expect(event.message).not_to include 'service'
      expect(event.structured_data[:'auth@43868']).not_to have_key :service
    end
  end

  let(:ruby_logger) { instance_double Logger }
  let(:service) { double(Resource, resource_id: 'rspec:webservice:test') }
  include_context("create user") { let(:login) { 'alice' } }
end
