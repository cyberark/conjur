# frozen_string_literal: true

require 'spec_helper'

describe Audit::Event::IssuerVariable do
  let(:user_id) { 'user123' }
  let(:client_ip) { '192.168.1.1' }
  let(:subject) do
    {
      resource_id: 'resource123',
      account: 'account123',
      issuer: 'issuer123'
    }
  end
  let(:message_id) { 'msg123' }
  let(:success) { true }
  let(:operation) { 'delete' }
  let(:error_message) { 'An error occurred' }

  let(:issuer_variable) do
    Audit::Event::IssuerVariable.new(
      user_id: user_id,
      client_ip: client_ip,
      subject: subject,
      message_id: message_id,
      success: success,
      operation: operation,
      error_message: error_message
    )
  end

  describe '#progname' do
    it 'returns the progname' do
      expect(issuer_variable.progname).to eq(Audit::Event.progname)
    end
  end

  describe '#severity' do
    it 'returns the correct severity for success' do
      expect(issuer_variable.severity).to eq(Syslog::LOG_INFO)
    end

    context 'when the operation fails' do
      let(:success) { false }

      it 'returns the correct severity for failure' do
        expect(issuer_variable.severity).to eq(Syslog::LOG_WARNING)
      end
    end
  end

  describe '#to_s' do
    it 'returns the message' do
      expect(issuer_variable.to_s).to eq(issuer_variable.message)
    end
  end

  describe '#message' do
    it 'returns the success message' do
      expect(issuer_variable.message).to include(
        "#{subject[:resource_id]} removed as a result of the removal of " \
        "#{subject[:account]}:issuer:#{subject[:issuer]}"
      )
    end

    context 'when the operation fails' do
      let(:success) { false }

      it 'returns the failure message' do
        expect(issuer_variable.message).to include(
          "failed to remove #{subject[:resource_id]}, following the removal " \
          "of #{subject[:account]}:issuer:#{subject[:issuer]}"
        )
      end
    end
  end

  describe '#structured_data' do
    it 'returns the structured data' do
      expect(issuer_variable.structured_data).to be_a(Hash)
    end
  end

  describe '#facility' do
    it 'returns the correct facility' do
      expect(issuer_variable.facility).to eq(Syslog::LOG_AUTHPRIV)
    end
  end

  describe '#action_sd' do
    it 'returns the action structured data' do
      expect(issuer_variable.action_sd).to be_a(Hash)
    end
  end
end
