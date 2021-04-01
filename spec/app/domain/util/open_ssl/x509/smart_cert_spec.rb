require_relative 'shared_context'

RSpec.describe('Util::OpenSsl::X509::SmartCert') do
  include_context "certificate testing"

  context 'creation from a string' do
    let(:cert_str) { cert_with_spiffe_id.to_pem }
    subject(:cert) { Util::OpenSsl::X509::SmartCert.new(cert_str) }

    it "creates the correct cert from a string" do
      expect(cert).to eq(cert_with_spiffe_id)
    end
  end

  context 'creation from an existing Certificate instance' do
    subject(:cert) { Util::OpenSsl::X509::SmartCert.new(cert_with_spiffe_id) }

    it "creates the correct cert from a cert" do
      expect(cert).to eq(cert_with_spiffe_id)
    end
  end

  context 'a cert with a spiffe id' do
    subject(:cert) { smart_cert(reconstructed_cert(cert_with_spiffe_id)) }

    it "returns the SAN" do
      expect(cert.san).to eq(alt_name)
    end

    it "returns the common name" do
      expect(cert.common_name).to eq(common_name)
    end
  end

  context 'a cert without an alt name (spiffe id)' do
    subject(:cert) { smart_cert(reconstructed_cert(cert_without_san)) }

    it "returns nil" do
      expect(cert.san).to be_nil
    end
  end
end
