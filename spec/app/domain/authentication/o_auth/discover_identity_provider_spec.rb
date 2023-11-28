# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::OAuth::DiscoverIdentityProvider) do
  let(:test_provider_uri) { 'http://test-provider-uri' }
  let(:test_error) { "test-error" }

  let(:transporter) do
    class_double(::Authentication::Util::NetworkTransporter).tap do |double|
      allow(double).to receive(:new).and_return(transport)
    end
  end

  let(:transport) do
    instance_double(::Authentication::Util::NetworkTransporter)
  end

  context "A discoverable identity provider" do
    before do
      transport.tap do |double|
        allow(double).to receive(:get).with('http://test-provider-uri/.well-known/openid-configuration').and_return(
          SuccessResponse.new({ 'jwks_uri' => 'http://test-provider-uri/jwks' })
        )
        allow(double).to receive(:get).with('http://test-provider-uri/jwks').and_return(
          # rubocop:disable Layout:LineLength
          SuccessResponse.new(
            {
              'keys' => [
                {
                  'kty' => 'RSA',
                  'use' => 'sig',
                  'kid' => '9GmnyFPkhc3hOuR22mvSvgnLo7Y',
                  'x5t' => '9GmnyFPkhc3hOuR22mvSvgnLo7Y',
                  'n' => 'z_w-5U4eZwenXYnEgt2rCN-753YQ7RN8ykiNprNiLl4ilpwAGLWF1cssoRflsSiBVZcCSwUzUwsifG7sbRq9Vc8RFs72Gg0AUwPsJFUqNttMg3Ot-wTqsZtE5GNSBUSqnI-iWoZfjw-uLsS0u4MfzP8Fpkd-rzRlifuIAYK8Ffi1bldkszeBzQbBZbXFwiw5uTf8vEAkH_IAdB732tQAsNXpWWYDV74nKAiwLlDS5FWVs2S2T-MPNAg28MLxYfRhW2bUpd693inxI8WTSLRncouzMImJF4XeMG2ZRZ0z_KJra_uzzMCLbILtpnLA95ysxWw-4ygm3MxN2iBM2IaJeQ',
                  'e' => 'AQAB',
                  'x5c' => ['MIIC/jCCAeagAwIBAgIJAOCJOVRxNKcNMA0GCSqGSIb3DQEBCwUAMC0xKzApBgNVBAMTImFjY291bnRzLmFjY2Vzc2NvbnRyb2wud2luZG93cy5uZXQwHhcNMjMwODI4MjAwMjQwWhcNMjgwODI4MjAwMjQwWjAtMSswKQYDVQQDEyJhY2NvdW50cy5hY2Nlc3Njb250cm9sLndpbmRvd3MubmV0MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAz/w+5U4eZwenXYnEgt2rCN+753YQ7RN8ykiNprNiLl4ilpwAGLWF1cssoRflsSiBVZcCSwUzUwsifG7sbRq9Vc8RFs72Gg0AUwPsJFUqNttMg3Ot+wTqsZtE5GNSBUSqnI+iWoZfjw+uLsS0u4MfzP8Fpkd+rzRlifuIAYK8Ffi1bldkszeBzQbBZbXFwiw5uTf8vEAkH/IAdB732tQAsNXpWWYDV74nKAiwLlDS5FWVs2S2T+MPNAg28MLxYfRhW2bUpd693inxI8WTSLRncouzMImJF4XeMG2ZRZ0z/KJra/uzzMCLbILtpnLA95ysxWw+4ygm3MxN2iBM2IaJeQIDAQABoyEwHzAdBgNVHQ4EFgQU/wzRzxsifMCz54SZ3HuF4P4jtzowDQYJKoZIhvcNAQELBQADggEBACaWlbJTObDai8+wmskHedKYb3FCfTwvH/sCRsygHIeDIi23CpoWeKt5FwXsSeqDMd0Hb6IMtYDG5rfGvhkNfunt3sutK0VpZZMNdSBmIXaUx4mBRRUsG4hpeWRrHRgTnxweDDVw4Mv+oYCmpY7eZ4SenISkSd/4qrXzFaI9NeZCY7Jg9vg1bev+NaUtD3C4As6GQ+mN8Rm2NG9vzgTDlKf4Wb5Exy7u9dMW1TChiy28ieVkETKdqwXcbhqM8GOLBUFicdmgP2y9aDGjb89BuaeoHJCGpWWCi3UZth14clVzC6p7ZD6fFx5tKMOL/hQvs3ugGtvFDWCsvcT8bB84RO8=']
                }
              ]
            }
          )
          # rubocop:enable Layout:LineLength
        )
      end
    end
    subject { Authentication::OAuth::DiscoverIdentityProvider.new(client: transporter).call(provider_uri: test_provider_uri, ca_cert: nil) }

    it "does not raise an error" do
      # rubocop:disable Layout/SingleLineBlockChain
      expect { subject }.to_not raise_error
      # rubocop:enable Layout/SingleLineBlockChain
    end

    it "returns the discovered provider" do
      expect(subject.jwks.first['kid']).to eq('9GmnyFPkhc3hOuR22mvSvgnLo7Y')
    end
  end

  context "A non-discoverable identity provider" do
    context "that fails on a timeout error" do
      before do
        transport.tap do |double|
          allow(double).to receive(:get).and_return(error_response)
        end
      end

      let(:error_response) { FailureResponse.new('error', exception: Errno::ETIMEDOUT.new) }
      subject { Authentication::OAuth::DiscoverIdentityProvider.new(client: transporter).call(provider_uri: test_provider_uri, ca_cert: nil) }

      it "returns a ProviderDiscoveryTimeout error" do
        # rubocop:disable Layout/SingleLineBlockChain
        expect { subject }.to raise_error(Errors::Authentication::OAuth::ProviderDiscoveryTimeout)
        # rubocop:enable Layout/SingleLineBlockChain
      end

      context "that fails on a general error" do
        let(:error_response) { FailureResponse.new(Net::HTTPNotFound) }
        subject { Authentication::OAuth::DiscoverIdentityProvider.new(client: transporter).call(provider_uri: test_provider_uri, ca_cert: nil) }

        it "returns a ProviderDiscoveryFailed error" do
          # rubocop:disable Layout/SingleLineBlockChain
          expect { subject }.to raise_error(Errors::Authentication::OAuth::ProviderDiscoveryFailed)
          # rubocop:enable Layout/SingleLineBlockChain
        end
      end
    end
  end
end
