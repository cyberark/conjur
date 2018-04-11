require 'active_support'
require 'spec_helper'

require 'helpers/errors_matcher'

require 'webrick'
require 'webrick/https'

describe 'SSL connection' do
  context 'with an untrusted certificate' do
    it 'fails' do
      expect { Conjur::API.login 'foo', 'bar', account: "the-account" }.to \
          raise_one_of(RestClient::SSLCertificateNotVerified, OpenSSL::SSL::SSLError)
    end
  end

  context 'with certificate added to the default OpenSSL cert store' do
    before do
      store = OpenSSL::X509::Store.new
      store.add_cert cert
      stub_const 'OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE', store
    end

    it 'works' do
      expect { Conjur::API.login 'foo', 'bar', account: "the-account" }.to raise_error RestClient::ResourceNotFound
    end
  end
  
  let(:server) do
    server = WEBrick::HTTPServer.new \
        Port: 0, SSLEnable: true,
        AccessLog: [], Logger: Logger.new('/dev/null'), # shut up, WEBrick
        SSLCertificate: cert, SSLPrivateKey: key
  end
  let(:port) { server.config[:Port] }

  before do
    allow(Conjur.configuration).to receive(:authn_url).and_return "https://localhost:#{port}"
  end

  around do |example|
    server_thread = Thread.new do
      server.start
    end
    example.run
    server.shutdown
    server_thread.join
  end

  let(:cert) do
    OpenSSL::X509::Certificate.new """
      -----BEGIN CERTIFICATE-----
      MIIBpDCCAQ2gAwIBAgIJALVPXQuF0w39MA0GCSqGSIb3DQEBCwUAMBQxEjAQBgNV
      BAMMCWxvY2FsaG9zdDAeFw0xNTAyMTQxNTE0MDFaFw0yNTAyMTExNTE0MDFaMBQx
      EjAQBgNVBAMMCWxvY2FsaG9zdDCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA
      n+IqEsmbuZk7E2GdPZpBxETjXC+dGze5XlZHPyKviekQ9sachAsBWApVrjM2QDtf
      KOwa6GuBqGQ0bdl4Ui7I0CIGB4a0UJHU/EvuDhI1cTzAVVWemW1QaqKxI/2xDgs9
      bqY471iVirRiSYD+6lm2pFYqOnnR/d+QKIMXhPOi0DMCAwEAATANBgkqhkiG9w0B
      AQsFAAOBgQCSPchDKAiVPNJlRkaY9KPIXfPbFX6h/+ilJRl1xtHqY+y4SxURbnU0
      fbYVnapKiuMnrnxTWXwl1z1iMbuuzjUC0RDz8F9pZkQ9IJpBSOaSfyUmk1JrrBRU
      INyaxnJjtc7YIzW1Yz7+aKtzZAQuFXNhiQa+CIIGeWrpzbExo2ce3Q==
      -----END CERTIFICATE-----
    """.lines.map(&:strip).join("\n")
  end

  let(:key) do
    OpenSSL::PKey.read """
      -----BEGIN RSA PRIVATE KEY-----
      MIICXAIBAAKBgQCf4ioSyZu5mTsTYZ09mkHERONcL50bN7leVkc/Iq+J6RD2xpyE
      CwFYClWuMzZAO18o7Broa4GoZDRt2XhSLsjQIgYHhrRQkdT8S+4OEjVxPMBVVZ6Z
      bVBqorEj/bEOCz1upjjvWJWKtGJJgP7qWbakVio6edH935AogxeE86LQMwIDAQAB
      AoGAUCDb7zCFUB4gglUgpfgCT+gqflAKj9J8n2/kIxsyGI7rBpKBbJfLY6FCUZyu
      6sAWr/6seaEviQI3WHpuF9oEn6gzb1XWpKH7h9ZAu5O2sscdrc5MrpFmBvGjMBnd
      80u/TcsDHX453QbPgqOJTi+Qt15Y+Ot/iE8ccQjW6pMPiCECQQDLQvNekVF7YJ9e
      iJNZSJMcx2c9hjAuywm/jPX+57k0xRlxGKCQxyujmxDfztDYU9kHMRHknbxz0sFr
      0Vkaxo1DAkEAyV3z6vvTtUx7R5IYOUkZqIfeQ6k6ZItQoZdZPKoBW0s7QhqvJyZN
      qeYJMaFR87A6273LwhpXZTvQwSYUUw6KUQJAQAIfXaJphG7TARQFQtKF8UQiEM/X
      EIVD1pxvQwx52FJRRro4ph7ycRz93Vzli5or+AXN2q6Jj/fIjUlpw/LOvQJAfyPO
      FUjpM+hVUiwhFVJdW/ZlVK0tzDvWLiDkXBQvBRhsEuHMQ1jA4ov2tBpaJxXXI9Uj
      KKv/EFEDDmDfpk1g8QJBAIJhDsxKWgUy1lk+lGYdWRQi/D/BnkNbySklCypmZghu
      Q6oXJNYB9NWLRWDJaGHlHrAn40Wq6MUx95Aomvj+uHA=
      -----END RSA PRIVATE KEY-----
    """.lines.map(&:strip).join("\n")
  end
end
