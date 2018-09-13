__END__
require 'csr'
# require 'app/domain/util/open_ssl/x509/request'

private_key = OpenSSL::PKey::RSA.new(1048)
altnames = ['URI:spiffe://cluster.local/namespace/foo/pod/bar']

csr = CSR.new(
  country: 'US',
  state: 'CA',
  city: 'San Francisco',
  department: 'Web',
  organization: 'Example Inc.',
  common_name: 'example.com',
  email: 'john@example.com',
  private_key: private_key
).request

# prepare SAN extension
extensions = [
  OpenSSL::X509::ExtensionFactory.new.create_extension('subjectAltName', altnames.join(','))
]

# add SAN extension to the CSR
attribute_values = OpenSSL::ASN1::Set [OpenSSL::ASN1::Sequence(extensions)]
[
  OpenSSL::X509::Attribute.new('extReq', attribute_values),
  OpenSSL::X509::Attribute.new('msExtReq', attribute_values)
].each do |attribute|
  csr.add_attribute(attribute)
end

# sign CSR with the signing key
csr.sign(private_key, OpenSSL::Digest::SHA256.new)

__END__
RSpec.describe 'Util::OpenSsl::X509::Request' do

  def authenticator(pass:)
    double('Authenticator').tap do |x|
      allow(x).to receive(:valid?).and_return(pass)
    end
  end

  def input(
    authenticator_name: 'authn-always-pass',
    service_id: nil,
    account: 'my-acct',
    username: 'my-user',
    password: 'my-pw',
    origin: '127.0.0.1'
  )
    Authentication::Strategy::Input.new(
      authenticator_name: authenticator_name,
      service_id: service_id,
      account: account,
      username: username,
      password: password,
      origin: origin
    )
  end

  let (:authenticators) do
    {
      'authn-always-pass' => authenticator(pass: true),
      'authn-always-fail' => authenticator(pass: false)
    }
  end

  ####################################
  # Security doubles
  ####################################

  let (:passing_security) do
    double('Security').tap do |x|
      allow(x).to receive(:validate)
    end
  end

  let (:failing_security) do
    double('Security').tap do |x|
      allow(x).to receive(:validate).and_raise('FAKE_SECURITY_ERROR')
    end
  end

  ####################################
  # ENV doubles
  ####################################

  let (:two_authenticator_env) do
    {'CONJUR_AUTHENTICATORS' => 'authn-always-pass, authn-always-fail'}
  end

  let (:blank_env) { Hash.new }

  ####################################
  # TokenFactory double
  ####################################

  # NOTE: For _this_ class, the details of actual Conjur tokens are irrelevant
  #
  let (:a_new_token) { 'A NICE NEW TOKEN' }

  let (:token_factory) do
    double('TokenFactory', signed_token: a_new_token)
  end

#  ____  _   _  ____    ____  ____  ___  ____  ___ 
# (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
#   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
#  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/


  context "An unavailable authenticator" do
    subject do
      Authentication::Strategy.new(
        authenticators: authenticators,
        security: passing_security,
        env: two_authenticator_env,
        token_factory: token_factory,
        audit_log: nil,
        role_cls: nil
      )
    end

    it "raises AuthenticatorNotFound" do
      input_ = input(authenticator_name: 'AUTHN-MISSING')
      expect{ subject.conjur_token(input_) }.to raise_error(
        Authentication::Strategy::AuthenticatorNotFound
      )
    end
  end

  context "An available authenticator" do
    context "that passes Security checks" do
      subject do
        Authentication::Strategy.new(
          authenticators: authenticators,
          security: passing_security,
          env: two_authenticator_env,
          token_factory: token_factory,
          audit_log: nil,
          role_cls: nil
        )
      end

      context "and receives invalid credentials" do
        it "raises InvalidCredentials" do
          input_ = input(authenticator_name: 'authn-always-fail')
          expect{ subject.conjur_token(input_) }.to raise_error(
            Authentication::Strategy::InvalidCredentials
          )
        end
      end

      context "and receives valid credentials" do
        it "returns a new token" do
          allow(subject).to receive(:validate_origin) { true }

          input_ = input(authenticator_name: 'authn-always-pass')
          expect(subject.conjur_token(input_)).to equal(a_new_token)
        end
      end
    end

    context "that fails Security checks" do
      subject do
        Authentication::Strategy.new(
          authenticators: authenticators,
          security: failing_security,
          env: two_authenticator_env,
          token_factory: token_factory,
          audit_log: nil,
          role_cls: nil
        )
      end

      it "raises an error" do
        input_ = input(authenticator_name: 'authn-always-pass')
        expect{ subject.conjur_token(input_) }.to raise_error(
          /FAKE_SECURITY_ERROR/
        )
      end
    end
  end
end
