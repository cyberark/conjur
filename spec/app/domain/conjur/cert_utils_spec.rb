require 'spec_helper'

describe Conjur::CertUtils do
  describe '.parse_certs' do
    let(:cert1_raw) do
      """-----BEGIN CERTIFICATE-----
MIIDPjCCAiagAwIBAgIVAKW1gdmOFrXt6xB0iQmYQ4z8Pf+kMA0GCSqGSIb3DQEB
CwUAMD0xETAPBgNVBAoTCGN1Y3VtYmVyMRIwEAYDVQQLEwlDb25qdXIgQ0ExFDAS
BgNVBAMTC2N1a2UtbWFzdGVyMB4XDTE1MTAwNzE2MzAwNloXDTI1MTAwNDE2MzAw
NlowFjEUMBIGA1UEAwwLY3VrZS1tYXN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IB
DwAwggEKAoIBAQC9e8bGIHOLOypKA4lsLcAOcDLAq+ICuVxn9Vg0No0m32Ok/K7G
uEGtlC8RidObntblUwqdX2uP7mqAQm19j78UTl1KT97vMmmFrpVZ7oQvEm1FUq3t
FBmJglthJrSbpdZjLf7a7eL1NnunkfBdI1DK9QL9ndMjNwZNFbXhld4fC5zuSr/L
PxawSzTEsoTaB0Nw0DdRowaZgrPxc0hQsrj9OF20gTIJIYO7ctZzE/JJchmBzgI4
CdfAYg7zNS+0oc0ylV0CWMerQtLICI6BtiQ482bCuGYJ00NlDcdjd3w+A2cj7PrH
wH5UhtORL5Q6i9EfGGUCDbmfpiVD9Bd3ukbXAgMBAAGjXDBaMA4GA1UdDwEB/wQE
AwIFoDAdBgNVHQ4EFgQU2jmj7l5rSw0yVb/vlWAYkK/YBwkwKQYDVR0RBCIwIIIL
Y3VrZS1tYXN0ZXKCCWxvY2FsaG9zdIIGY29uanVyMA0GCSqGSIb3DQEBCwUAA4IB
AQBCepy6If67+sjuVnT9NGBmjnVaLa11kgGNEB1BZQnvCy0IN7gpLpshoZevxYDR
3DnPAetQiZ70CSmCwjL4x6AVxQy59rRj0Awl9E1dgFTYI3JxxgLsI9ePdIRVEPnH
dhXqPY5ZIZhvdHlLStjsXX7laaclEtMeWfSzxe4AmP/Sm/er4ks0gvLQU6/XJNIu
RnRH59ZB1mZMsIv9Ii790nnioYFR54JmQu1JsIib77ZdSXIJmxAtraJSTLcZbU1E
+SM3XCE423Xols7onyluMYDy3MCUTFwoVMRBcRWCAk5gcv6XvZDfLi6Zwdne6x3Y
bGenr4vsPuSFsycM03/EcQDT
-----END CERTIFICATE-----
"""
    end
    let(:cert2_raw) do
      """-----BEGIN CERTIFICATE-----
MIIDhzCCAm+gAwIBAgIJAJnsrJ1+j9MhMA0GCSqGSIb3DQEBCwUAMD0xETAPBgNV
BAoTCGN1Y3VtYmVyMRIwEAYDVQQLEwlDb25qdXIgQ0ExFDASBgNVBAMTC2N1a2Ut
bWFzdGVyMB4XDTE1MTAwNzE2MzAwM1oXDTI1MTAwNDE2MzAwM1owPTERMA8GA1UE
ChMIY3VjdW1iZXIxEjAQBgNVBAsTCUNvbmp1ciBDQTEUMBIGA1UEAxMLY3VrZS1t
YXN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCsuZ06Ld4JDhxZ
FcxKVxu7MTjXVv6W8pI7qFKmgr39aNqmDpKYJ1H9aM+r9zaTAeithpM4wJpVswkJ
d0RSuKdm1LOx11yHLyZ1OvlPHFhsVWdZIQZ6R9srhPYBUCMem4sHR5IAcBBX+HkR
35gaPYUl1uFV/9zCniekt92Kdta+it1WL7XinXTBURlhDawiD/kv1C9x6dICEJVe
IT/jRohmqHAoM/JSOQTthaDli3Qvu5K8XAx8UXvWVmv3eStZFVDbC4ZEueRd9KAe
4IZ5FxdpFYkPBgt2lBYeydYKRShyYrDKye1uJBDkeplNaYW4cS4mOhYuRkdKn7MH
uY/xb1lFAgMBAAGjgYkwgYYwKQYDVR0RBCIwIIILY3VrZS1tYXN0ZXKCCWxvY2Fs
aG9zdIIGY29uanVyMB0GA1UdDgQWBBRHpGF7aQbHdORYgQKDC2hV6NzEKzAfBgNV
HSMEGDAWgBRHpGF7aQbHdORYgQKDC2hV6NzEKzAMBgNVHRMEBTADAQH/MAsGA1Ud
DwQEAwIB5jANBgkqhkiG9w0BAQsFAAOCAQEAGZT9Wek1hYluIVaxu03wSKCKIJ4p
KxTHw+mLDapg1y9t3Fa/5IQQK0Bx0xGU2qWiQKjda3vdFPJWO6l6XJvsUY5Nwtm5
Gcsk8l3L/zWCrjrFTH3TdVad5E+DTwVhThelmEjw68AyM+WuOL61j0MItd9mLW74
Lv2zouj9nQBdnUBHWQ0EL/9d5cfaCVu/bFlDfYt7Yj0IzXCuaWZfJeHodU1hmqVX
BvYRjnTB2LSxfmSnkrCeFPmhE11bWVtsLIdrGIgtEMX0/s9xg58QuNnva1U3pJsW
RjvSxre4Xg2qlI9Laybb4oZ4g6DI8hRbL0VdFAsveg6SXg2RxgJcXeJUFw==
-----END CERTIFICATE-----
"""
    end

    let(:cert1) { OpenSSL::X509::Certificate.new(cert1_raw) }
    let(:cert2) { OpenSSL::X509::Certificate.new(cert2_raw) }

    it 'parses a certificate' do
      expect(Conjur::CertUtils.parse_certs(cert1_raw).map(&:to_der))\
        .to eq([cert1.to_der])
    end

    it 'parses two certificates' do
      expect(Conjur::CertUtils.parse_certs(cert1_raw + cert2_raw).map(&:to_der))\
        .to eq([cert1.to_der, cert2.to_der])
    end

    it 'parses the certificate correctly even if the whitespace is wrong' do
      bad_whitespace = cert1_raw.gsub("\n", " ")
      expect(Conjur::CertUtils.parse_certs(bad_whitespace).map(&:to_der))\
        .to eq([cert1.to_der])
    end

    it 'shows a bad cert in error message' do
      bad_cert = "-----BEGIN CERTIFICATE-----\nfoo\n-----END CERTIFICATE-----\n"
      expect do
        Conjur::CertUtils.parse_certs(bad_cert)
      end.to raise_error(OpenSSL::X509::CertificateError) do |exn|
        expect(exn.message).to include(bad_cert)
      end
    end
  end

  describe '.add_chained_cert' do
    let(:one_certificate_chain) do
      """-----BEGIN CERTIFICATE-----
MIIDPjCCAiagAwIBAgIVAKW1gdmOFrXt6xB0iQmYQ4z8Pf+kMA0GCSqGSIb3DQEB
CwUAMD0xETAPBgNVBAoTCGN1Y3VtYmVyMRIwEAYDVQQLEwlDb25qdXIgQ0ExFDAS
BgNVBAMTC2N1a2UtbWFzdGVyMB4XDTE1MTAwNzE2MzAwNloXDTI1MTAwNDE2MzAw
NlowFjEUMBIGA1UEAwwLY3VrZS1tYXN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IB
DwAwggEKAoIBAQC9e8bGIHOLOypKA4lsLcAOcDLAq+ICuVxn9Vg0No0m32Ok/K7G
uEGtlC8RidObntblUwqdX2uP7mqAQm19j78UTl1KT97vMmmFrpVZ7oQvEm1FUq3t
FBmJglthJrSbpdZjLf7a7eL1NnunkfBdI1DK9QL9ndMjNwZNFbXhld4fC5zuSr/L
PxawSzTEsoTaB0Nw0DdRowaZgrPxc0hQsrj9OF20gTIJIYO7ctZzE/JJchmBzgI4
CdfAYg7zNS+0oc0ylV0CWMerQtLICI6BtiQ482bCuGYJ00NlDcdjd3w+A2cj7PrH
wH5UhtORL5Q6i9EfGGUCDbmfpiVD9Bd3ukbXAgMBAAGjXDBaMA4GA1UdDwEB/wQE
AwIFoDAdBgNVHQ4EFgQU2jmj7l5rSw0yVb/vlWAYkK/YBwkwKQYDVR0RBCIwIIIL
Y3VrZS1tYXN0ZXKCCWxvY2FsaG9zdIIGY29uanVyMA0GCSqGSIb3DQEBCwUAA4IB
AQBCepy6If67+sjuVnT9NGBmjnVaLa11kgGNEB1BZQnvCy0IN7gpLpshoZevxYDR
3DnPAetQiZ70CSmCwjL4x6AVxQy59rRj0Awl9E1dgFTYI3JxxgLsI9ePdIRVEPnH
dhXqPY5ZIZhvdHlLStjsXX7laaclEtMeWfSzxe4AmP/Sm/er4ks0gvLQU6/XJNIu
RnRH59ZB1mZMsIv9Ii790nnioYFR54JmQu1JsIib77ZdSXIJmxAtraJSTLcZbU1E
+SM3XCE423Xols7onyluMYDy3MCUTFwoVMRBcRWCAk5gcv6XvZDfLi6Zwdne6x3Y
bGenr4vsPuSFsycM03/EcQDT
-----END CERTIFICATE-----
"""
    end

    let(:two_certificates_chain) do
      """-----BEGIN CERTIFICATE-----
MIIDPjCCAiagAwIBAgIVAKW1gdmOFrXt6xB0iQmYQ4z8Pf+kMA0GCSqGSIb3DQEB
CwUAMD0xETAPBgNVBAoTCGN1Y3VtYmVyMRIwEAYDVQQLEwlDb25qdXIgQ0ExFDAS
BgNVBAMTC2N1a2UtbWFzdGVyMB4XDTE1MTAwNzE2MzAwNloXDTI1MTAwNDE2MzAw
NlowFjEUMBIGA1UEAwwLY3VrZS1tYXN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IB
DwAwggEKAoIBAQC9e8bGIHOLOypKA4lsLcAOcDLAq+ICuVxn9Vg0No0m32Ok/K7G
uEGtlC8RidObntblUwqdX2uP7mqAQm19j78UTl1KT97vMmmFrpVZ7oQvEm1FUq3t
FBmJglthJrSbpdZjLf7a7eL1NnunkfBdI1DK9QL9ndMjNwZNFbXhld4fC5zuSr/L
PxawSzTEsoTaB0Nw0DdRowaZgrPxc0hQsrj9OF20gTIJIYO7ctZzE/JJchmBzgI4
CdfAYg7zNS+0oc0ylV0CWMerQtLICI6BtiQ482bCuGYJ00NlDcdjd3w+A2cj7PrH
wH5UhtORL5Q6i9EfGGUCDbmfpiVD9Bd3ukbXAgMBAAGjXDBaMA4GA1UdDwEB/wQE
AwIFoDAdBgNVHQ4EFgQU2jmj7l5rSw0yVb/vlWAYkK/YBwkwKQYDVR0RBCIwIIIL
Y3VrZS1tYXN0ZXKCCWxvY2FsaG9zdIIGY29uanVyMA0GCSqGSIb3DQEBCwUAA4IB
AQBCepy6If67+sjuVnT9NGBmjnVaLa11kgGNEB1BZQnvCy0IN7gpLpshoZevxYDR
3DnPAetQiZ70CSmCwjL4x6AVxQy59rRj0Awl9E1dgFTYI3JxxgLsI9ePdIRVEPnH
dhXqPY5ZIZhvdHlLStjsXX7laaclEtMeWfSzxe4AmP/Sm/er4ks0gvLQU6/XJNIu
RnRH59ZB1mZMsIv9Ii790nnioYFR54JmQu1JsIib77ZdSXIJmxAtraJSTLcZbU1E
+SM3XCE423Xols7onyluMYDy3MCUTFwoVMRBcRWCAk5gcv6XvZDfLi6Zwdne6x3Y
bGenr4vsPuSFsycM03/EcQDT
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIDhzCCAm+gAwIBAgIJAJnsrJ1+j9MhMA0GCSqGSIb3DQEBCwUAMD0xETAPBgNV
BAoTCGN1Y3VtYmVyMRIwEAYDVQQLEwlDb25qdXIgQ0ExFDASBgNVBAMTC2N1a2Ut
bWFzdGVyMB4XDTE1MTAwNzE2MzAwM1oXDTI1MTAwNDE2MzAwM1owPTERMA8GA1UE
ChMIY3VjdW1iZXIxEjAQBgNVBAsTCUNvbmp1ciBDQTEUMBIGA1UEAxMLY3VrZS1t
YXN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCsuZ06Ld4JDhxZ
FcxKVxu7MTjXVv6W8pI7qFKmgr39aNqmDpKYJ1H9aM+r9zaTAeithpM4wJpVswkJ
d0RSuKdm1LOx11yHLyZ1OvlPHFhsVWdZIQZ6R9srhPYBUCMem4sHR5IAcBBX+HkR
35gaPYUl1uFV/9zCniekt92Kdta+it1WL7XinXTBURlhDawiD/kv1C9x6dICEJVe
IT/jRohmqHAoM/JSOQTthaDli3Qvu5K8XAx8UXvWVmv3eStZFVDbC4ZEueRd9KAe
4IZ5FxdpFYkPBgt2lBYeydYKRShyYrDKye1uJBDkeplNaYW4cS4mOhYuRkdKn7MH
uY/xb1lFAgMBAAGjgYkwgYYwKQYDVR0RBCIwIIILY3VrZS1tYXN0ZXKCCWxvY2Fs
aG9zdIIGY29uanVyMB0GA1UdDgQWBBRHpGF7aQbHdORYgQKDC2hV6NzEKzAfBgNV
HSMEGDAWgBRHpGF7aQbHdORYgQKDC2hV6NzEKzAMBgNVHRMEBTADAQH/MAsGA1Ud
DwQEAwIB5jANBgkqhkiG9w0BAQsFAAOCAQEAGZT9Wek1hYluIVaxu03wSKCKIJ4p
KxTHw+mLDapg1y9t3Fa/5IQQK0Bx0xGU2qWiQKjda3vdFPJWO6l6XJvsUY5Nwtm5
Gcsk8l3L/zWCrjrFTH3TdVad5E+DTwVhThelmEjw68AyM+WuOL61j0MItd9mLW74
Lv2zouj9nQBdnUBHWQ0EL/9d5cfaCVu/bFlDfYt7Yj0IzXCuaWZfJeHodU1hmqVX
BvYRjnTB2LSxfmSnkrCeFPmhE11bWVtsLIdrGIgtEMX0/s9xg58QuNnva1U3pJsW
RjvSxre4Xg2qlI9Laybb4oZ4g6DI8hRbL0VdFAsveg6SXg2RxgJcXeJUFw==
-----END CERTIFICATE-----
"""
    end

    let(:store){ double('default store') }

    context 'with one certificate in the chain' do
      subject{ Conjur::CertUtils.add_chained_cert(store, one_certificate_chain) }

      it 'adds one certificate to the store' do
        expect(store).to receive(:add_cert).once
        expect(subject).to be_truthy
      end
    end

    context 'with two certificate in the chain' do
      subject{ Conjur::CertUtils.add_chained_cert(store, two_certificates_chain) }

      it 'adds both certificate to the store' do
        expect(store).to receive(:add_cert).twice
        expect(subject).to be_truthy
      end
    end
  end
end
