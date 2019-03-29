# frozen_string_literal: true

require 'spec_helper'

describe ::CA::X509::Certificate do
  
  describe '#to_formatted' do
    
    let(:certificate_formatted) do
      <<~CERT
        -----BEGIN CERTIFICATE-----
        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
        jq92Xz5dxg==
        -----END CERTIFICATE-----
      CERT
    end

    let(:certificate) do
      OpenSSL::X509::Certificate.new(certificate_formatted)
    end

    let(:formatted_certificate) { ::CA::X509::Certificate.new(certificate:certificate).to_formatted }

    it "renders an x.509 certificate to PEM format" do
      expect(formatted_certificate.to_s).to eq(certificate_formatted)
    end

    it "returns a content type of 'application/x-pem-file" do
      expect(formatted_certificate.content_type).to eq('application/x-pem-file')
    end
  end
end
