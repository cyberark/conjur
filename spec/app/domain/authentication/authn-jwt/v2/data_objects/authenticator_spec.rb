# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnJwt::V2::DataObjects::Authenticator) do

  subject { Authentication::AuthnJwt::V2::DataObjects::Authenticator.new(account: 'foo', service_id: 'bar') }

  describe '.resource_id' do
    context 'when properly initialized' do
      it 'is formatted as expected' do
        expect(subject.resource_id).to eq('foo:webservice:conjur/authn-jwt/bar')
      end
    end
  end

  describe '.reserved_claims' do
    context 'when initialized' do
      it 'includes the reserved claims' do
        expect(subject.reserved_claims).to eq(['iss', 'exp', 'nbf', 'iat', 'jti', 'aud'])
      end
    end
  end

  describe '.token_ttl' do
    context 'when ttl is the default' do
      it 'is 8 minutes' do
        expect(subject.token_ttl.to_s).to eq('480')
      end
    end
    context 'when ttl is an invalid format' do
      ['foo', nil, ''].each do |invalid_format|
        context "when ttl is '#{invalid_format}'" do
          subject { Authentication::AuthnJwt::V2::DataObjects::Authenticator.new(account: 'foo', service_id: 'bar', token_ttl: invalid_format) }
          it 'raises the expected message' do
            expect { subject.token_ttl }.to raise_error(Errors::Authentication::DataObjects::InvalidTokenTTL)
          end
        end
      end
    end
  end

  describe '.enforced_claims' do
    let(:authenticator) { Authentication::AuthnJwt::V2::DataObjects::Authenticator }
    context 'when set' do
      {
        'foo' => ['foo'],
        'foo,bar' => ['foo', 'bar'],
        ' foo , bar' => ['foo', 'bar'],
        'foo, bar' => ['foo', 'bar'],
        'foo,bar ' => ['foo', 'bar'],
        nil => []
      }.each do |claim, result|
        context "when claim is '#{claim}'" do
          it 'returns the correctly formatted value' do
            local_authenticator = authenticator.new(account: 'foo', service_id: 'bar', enforced_claims: claim)
            expect(local_authenticator.enforced_claims).to eq(result)
          end
        end
      end
    end
  end

  describe '.claim_aliases_lookup' do
    let(:authenticator) { Authentication::AuthnJwt::V2::DataObjects::Authenticator }
    context 'when set' do
      {
        nil => {},
        '' => {},
        'foo:bar' => { 'foo' => 'bar' },
        'foo:bar, bing:baz' => { 'foo' => 'bar', 'bing' => 'baz' },
        ' foo: bar/baz ' => { 'foo' => 'bar/baz' }
      }.each do |claim, result|
        context "when claim alias is '#{claim}'" do
          it 'returns the correctly formatted value' do
            local_authenticator = authenticator.new(account: 'foo', service_id: 'bar', claim_aliases: claim)
            expect(local_authenticator.claim_aliases_lookup).to eq(result)
          end
        end
      end
    end
  end
end
