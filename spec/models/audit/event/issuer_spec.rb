# frozen_string_literal: true

require 'spec_helper'

describe Audit::Event::Issuer do
  let(:user_id) { 'user123' }
  let(:client_ip) { '192.168.1.1' }
  let(:subject) { { account: 'account1', issuer: 'issuer1' } }
  let(:message_id) { 'msg123' }
  let(:success) { true }
  let(:operation) { 'create' }
  let(:error_message) { 'An error occurred' }

  let(:issuer) do
    Audit::Event::Issuer.new(
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
      expect(issuer.progname).to eq('conjur')
    end
  end

  describe '#severity' do
    it 'returns the severity' do
      expect(issuer.severity).to eq(Syslog::LOG_INFO)
    end
  end

  describe '#to_s' do
    it 'returns the message' do
      expect(issuer.to_s).to eq(issuer.message)
    end
  end

  describe '#message' do
    context 'when operation is list' do
      let(:operation) { 'list' }

      it 'returns the correct success message' do
        expect(issuer.message).to include(
          "#{user_id} listed issuers #{subject[:account]}:issuer:#{subject[:issuer]}"
        )
      end

      context 'when the operation fails' do
        let(:success) { false }

        it 'returns the correct failure message' do
          expect(issuer.message).to include(
            "#{user_id} tried to list issuers #{subject[:account]}:issuer:#{subject[:issuer]}"
          )
        end
      end
    end

    context 'when operation is not list' do
      it 'returns the correct success message' do
        expect(issuer.message).to include(
          "#{user_id} created #{subject[:account]}:issuer:#{subject[:issuer]}"
        )
      end

      context 'when the operation fails' do
        let(:success) { false }

        it 'returns the correct failure message' do
          expect(issuer.message).to include(
            "#{user_id} tried to create #{subject[:account]}:issuer:#{subject[:issuer]}"
          )
        end
      end
    end
  end

  describe '#structured_data' do
    it 'returns the structured data' do
      expect(issuer.structured_data).to be_a(Hash)
    end
  end

  describe '#facility' do
    it 'returns the correct facility' do
      expect(issuer.facility).to eq(Syslog::LOG_AUTHPRIV)
    end
  end

  describe '#action_sd' do
    it 'returns the action structured data' do
      expect(issuer.action_sd).to be_a(Hash)
    end
  end

  describe '#==' do
    it 'returns true for equal objects' do
      other_issuer = issuer.dup
      expect(issuer).to eq(other_issuer)
    end

    it 'returns false for different objects' do
      other_issuer = described_class.new(
        user_id: 'different_user',
        client_ip: client_ip,
        subject: subject,
        message_id: message_id,
        success: success,
        operation: operation,
        error_message: error_message
      )
      expect(issuer).not_to eq(other_issuer)
    end
  end
end
