# The Certificate Authority (CA) module is responsible
# for providing certificate signing capabilities for
# Conjur PKI services.
module CA
  AVAILABLE_CA_TYPES = {
    x509: CA::X509
  }.freeze

  def self.from_type(type)
    AVAILABLE_CA_TYPES[type]
  end
end
