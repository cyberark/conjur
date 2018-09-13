require 'app/domain/util/open_ssl/x509/certificate'
require 'app/domain/util/open_ssl/x509/smart_csr'
require 'app/domain/util/open_ssl/x509/quick_csr'


RSpec.shared_context "certificate testing" do

  let(:common_name) { 'example.com' }
  let(:spiffe_id) { 'URI:spiffe://cluster.local/example' }
  let(:cert_subject) { "/CN=#{common_name}/OU=Conjur Kubernetes CA/O=conjur" }

  let(:csr_with_spiffe_id) do
    Util::OpenSsl::X509::QuickCsr.new(
      common_name: common_name,
      alt_names: [spiffe_id]
    ).request
  end

  let(:csr_without_spiffe_id) do
    Util::OpenSsl::X509::QuickCsr.new(common_name: 'example.com').request
  end

  let(:cert_with_spiffe_id) do
    Util::OpenSsl::X509::Certificate.from_subject(
      subject: cert_subject,
      alt_name: spiffe_id
    )
  end

  let(:cert_without_san) do
    Util::OpenSsl::X509::Certificate.from_subject(subject: cert_subject)
  end

  # Serializes and deserializes the CSR, then wraps it in Csr This
  # is needed to accurately simulate the way CSR are actually used, because the
  # internal objects differ depending on how the CSR is created.
  #
  def reconstructed_csr(csr)
    serialized = csr.to_pem
    deserialized = OpenSSL::X509::Request.new(serialized)
    Util::OpenSsl::X509::SmartCsr.new(deserialized)
  end

  def reconstructed_cert(cert)
    serialized = cert.to_pem
    OpenSSL::X509::Certificate.new(serialized)
  end

  def smart_csr(csr)
    Util::OpenSsl::X509::SmartCsr.new(csr)
  end

  def smart_cert(cert)
    Util::OpenSsl::X509::SmartCert.new(cert)
  end
end
