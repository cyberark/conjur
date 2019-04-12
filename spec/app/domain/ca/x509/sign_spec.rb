# frozen_string_literal: true

require 'spec_helper'

describe ::CA::X509::Sign do
  describe '#call' do
    let(:certificate_request) do
      ::CA::X509::CertificateRequest.from_hash(params.merge(role: role))
    end

    let(:issuer) do
      ::CA::X509::Issuer.from_resource(ca_resource)
    end

    let(:params) do
      {
        csr: csr
      }
    end

    let(:role) do
      double("role", 
        account: "rspec", 
        kind: "host", 
        identifier: "server",
        resource: role_resource) 
    end

    let(:role_resource) { double("role_resource", annotations: [])}

    let(:ca_resource) do 
      double(
        "ca_resource",
        account: "rspec", 
        identifier: "conjur/ca/x509",
        annotations: ca_resource_annotations)
    end

    let(:ca_resource_annotations) do
      [
        { name: 'ca/max-ttl', value: 'P1D' },
        { name: 'ca/private-key-password', value: private_key_password_id },
        { name: 'ca/private-key', value: private_key_id },
        { name: 'ca/certificate', value: cert_chain_id }
      ]
    end

    let(:env) { double("env") }

    let(:csr) do
      <<~CSR
        -----BEGIN CERTIFICATE REQUEST-----
        MIICvDCCAaQCAQAwdzELMAkGA1UEBhMCVVMxDTALBgNVBAgMBFV0YWgxDzANBgNV
        BAcMBkxpbmRvbjEWMBQGA1UECgwNRGlnaUNlcnQgSW5jLjERMA8GA1UECwwIRGln
        aUNlcnQxHTAbBgNVBAMMFGV4YW1wbGUuZGlnaWNlcnQuY29tMIIBIjANBgkqhkiG
        9w0BAQEFAAOCAQ8AMIIBCgKCAQEA8+To7d+2kPWeBv/orU3LVbJwDrSQbeKamCmo
        wp5bqDxIwV20zqRb7APUOKYoVEFFOEQs6T6gImnIolhbiH6m4zgZ/CPvWBOkZc+c
        1Po2EmvBz+AD5sBdT5kzGQA6NbWyZGldxRthNLOs1efOhdnWFuhI162qmcflgpiI
        WDuwq4C9f+YkeJhNn9dF5+owm8cOQmDrV8NNdiTqin8q3qYAHHJRW28glJUCZkTZ
        wIaSR6crBQ8TbYNE0dc+Caa3DOIkz1EOsHWzTx+n0zKfqcbgXi4DJx+C1bjptYPR
        BPZL8DAeWuA8ebudVT44yEp82G96/Ggcf7F33xMxe0yc+Xa6owIDAQABoAAwDQYJ
        KoZIhvcNAQEFBQADggEBAB0kcrFccSmFDmxox0Ne01UIqSsDqHgL+XmHTXJwre6D
        hJSZwbvEtOK0G3+dr4Fs11WuUNt5qcLsx5a8uk4G6AKHMzuhLsJ7XZjgmQXGECpY
        Q4mC3yT3ZoCGpIXbw+iP3lmEEXgaQL0Tx5LFl/okKbKYwIqNiyKWOMj7ZR/wxWg/
        ZDGRs55xuoeLDJ/ZRFf9bI+IaCUd1YrfYcHIl3G87Av+r49YVwqRDT0VDV7uLgqn
        29XI1PpVUNCPQGn9p/eX6Qo7vpDaPybRtA2R7XLKjQaF9oXWeCUqy1hvJac9QFO2
        97Ob1alpHPoZ7mWiEuJwjBPii6a9M9G30nUo39lBi1w=
        -----END CERTIFICATE REQUEST-----
      CSR
    end

    let(:private_key_variable) do
      double("private_key", secret: double("secret", value: private_key))
    end

    let(:private_key_id) { "conjur/ca/x509/private-key"}
    let(:cert_chain_id) { "conjur/ca/x509/cert-chain" }
    let(:private_key_password_id) { nil }

    let(:private_key) do
      <<~KEY
        -----BEGIN RSA PRIVATE KEY-----
        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
        -----END RSA PRIVATE KEY-----        
      KEY
    end

    let(:private_key_password) { nil }

    let(:cert_chain_variable) do
      double("cert_chain", secret: double("secret", value: cert_chain))
    end

    let(:cert_chain) do
      <<~CERT
        -----BEGIN CERTIFICATE-----
        MIIFqDCCA5CgAwIBAgIJANVyGlzdPTA9MA0GCSqGSIb3DQEBBQUAMG0xCzAJBgNV
        BAYTAlVTMQswCQYDVQQIDAJNQTEPMA0GA1UEBwwGTmV3dG9uMRowGAYDVQQKDBFD
        eWJlckFyayBTb2Z0d2FyZTEPMA0GA1UECwwGQ29uanVyMRMwEQYDVQQDDApjb25q
        dXIub3JnMB4XDTE5MDMxNTE3NTUwNFoXDTIxMTIwOTE3NTUwNFowUjELMAkGA1UE
        BhMCVVMxCjAIBgNVBAgMAS4xCjAIBgNVBAcMAS4xCjAIBgNVBAoMAS4xHzAdBgNV
        BAMMFkNvbmp1ciBJbnRlcm1lZGlhdGUgQ0EwggIiMA0GCSqGSIb3DQEBAQUAA4IC
        DwAwggIKAoICAQCgwM/YupHF0fED5PhcEK3yoXltwvuZw6hjvO1TvHOgUQCrwh3c
        TzPbCak5DuRsiD1/RHVYoukvj4gRT8AqVSmhw9YwxNeBVuzt9GnDe53i+m3DcWzL
        Lo41dl6xvPzjdFOnX+5QcU2GTKeD6R37bw2hm+mf9ppNZGuZ1mKOCWgJBUR+oZ03
        52hAr3+VZavs+F5atzD2Rc1Tx/fT9mbR23YxudiB5VX2xMUJFL+S7rcyh9W4hD9A
        P2Xq+0M5flQfDRueK+xko+SF6wtxlJLijwDboSsIL/RHb+11pwzWw7720491AAOQ
        7aex13luYoODP2kxMKGyZOxNm/38wzaMMjiwvMcTKPjtlIQVyQi3Zmo+kWwzbh6c
        FKDEAos+bKMddlI7GYIRlMJo/BrdfpEXpMGwiEo26FmASikWf+DxzvvomN45o1H5
        L3MHUk5XN8jnFyG8QXW9HjrU4+FPuz3+H5NdRiUu9Al0scFL/tFeLydVAbCO7FTf
        58PFzOQTmRzVYsIzeGoPomwZrg/LMESnqt1JDzERDNbLo1bJtVwDmE5UpvC5K3Y1
        KXV9t7+y5bcTQLQ6WqvtgDUQCVwE8uMcGilxuyvip1w+BIq06iNovyCI48TcMFvS
        6Rffk6N/iGpQ7cYlpUm9hYyRkFeBhzuyaFcqQgHvv8RyjGYfZSKLKs5phwIDAQAB
        o2YwZDAdBgNVHQ4EFgQUxaujnL1UptTKBDlx9oMxObLAnkwwHwYDVR0jBBgwFoAU
        mO3t3QZrFNV2GoU3qTWtW0ZYkNAwEgYDVR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8B
        Af8EBAMCAYYwDQYJKoZIhvcNAQEFBQADggIBAKMKT8Xtcu8FcZFFehlMeNbCxX99
        BZtv5S5SBREfXLG5xXlH0Z2gisoL7CXgpoSWA7lnajcoLteMFPuufylFh05fN4IK
        oax0ra5DlxcrRviCazZyQigUeSMFsPBJslQj9TkCL9JsI6V/lx8Oaoawv7eLpZzI
        o7o0zNq+V7Nk5L1911UH0IaLoK8D4u0yhwohbLadRMVgJxGkozVHbbWXXbHTr9W7
        CxqBez0E3lESq5MqReByDoy9Lt5JETIGGYN0WdMMZi0WfN2OuhrXvktYcu3QktXM
        E9cppnZXeXX/RAbxjr6UYU6fkOS/hKR/pQOq6cSRVS/yKliMpZ3C/0ooWt/VwSAM
        w1ywge/ga1F2LM9uX3GFyVH6+b5OQVlxjUmmaxiGv5pNzAUcoFfgDndcCtJ7y8yp
        mhK8Y7nBEjQ6k2/5YnmuGu3vfuar7aKhC9bIo3OCniHuPzscTGVHdlijCGot/XQJ
        79ogWPh/KC0qb5cRViB5isIorDIK0tPsP3OYfihdQWsT0oHMmir5s+lBSZ8XaecT
        OoJy6XRpxEJdUk4Zg/trtHBwDEzW9uH+sc/Hm1TRTfpZMYOc+LAQKxqXA+AEZkl0
        bxAfoQ2YPIFP3lyBPfpV+UvUbQqgWIquS0gla57fR0CRFu7aIUvL3wstY3976Fxr
        EblbLXg8vDSqpR2Q
        -----END CERTIFICATE-----
        -----BEGIN CERTIFICATE-----
        MIIFwDCCA6igAwIBAgIJAO6agxCcnACXMA0GCSqGSIb3DQEBCwUAMG0xCzAJBgNV
        BAYTAlVTMQswCQYDVQQIDAJNQTEPMA0GA1UEBwwGTmV3dG9uMRowGAYDVQQKDBFD
        eWJlckFyayBTb2Z0d2FyZTEPMA0GA1UECwwGQ29uanVyMRMwEQYDVQQDDApjb25q
        dXIub3JnMB4XDTE5MDMxNTE2MzQ0OVoXDTIxMDMxNDE2MzQ0OVowbTELMAkGA1UE
        BhMCVVMxCzAJBgNVBAgMAk1BMQ8wDQYDVQQHDAZOZXd0b24xGjAYBgNVBAoMEUN5
        YmVyQXJrIFNvZnR3YXJlMQ8wDQYDVQQLDAZDb25qdXIxEzARBgNVBAMMCmNvbmp1
        ci5vcmcwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC3eQXjUPM0r2Vc
        ZHrD4Lx/5IYBT18SrO0SvJ23BYXAqmyP7tJHBupq/w7V6/HH7XKSC3PWFgURQYez
        xJ3ozos8ttBuKl0LfV0qhw8zoPg+iiy20dSntzHM3TfsHCaTuhLapln9ZVyvFIIp
        /qjMVYujym6uXJzUiDsn4+KRFQqxH52drxjrFT7yXqtb0eGa3aX00avwfz+7G3lT
        +LPwjNunX+fp4C6RkPDN5T8znQpIoqU8pFL6Y0qaU1ppTFKhX/WqlWykGG6/9rRL
        8PSKwwZlAPw9RsalAoZzLs0LMBNV3VqHe9ATZtxJnnU5D69OaIq+7MGubbUfhylW
        CvnZ2mslpLkMk+AGs6joQbC0fDH6/8miccrVjoWZm8Sy+6HVoxlfS6yTmNMa5RuY
        /XZU8mVsgrXP2DZz9tLGbAKUo9cL4XOrdHUBCzhzrBNYj0DQRjp7wXpVxsz3DbHm
        m0SRmNSHPbBzAhVmm9o2fxHtEO4erE8KntXMGhwGPEhSjxFAbXju9pGfq8GeTYio
        +uwT7/HgHAZVUSBZTPb/ltigPkKb6Np4Pt25QtiSJBYDT7Y2Ejo0mZlvQNBJLFFE
        6qJWj3xWimcofmHnRdH01XurnxhgtHiz6pN7JF4LWVA3N08HIUYIW8VfDYbm9Q5B
        tXmn3Befh5zk7+oyZxOhxEgne7qhDwIDAQABo2MwYTAdBgNVHQ4EFgQUmO3t3QZr
        FNV2GoU3qTWtW0ZYkNAwHwYDVR0jBBgwFoAUmO3t3QZrFNV2GoU3qTWtW0ZYkNAw
        DwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAYYwDQYJKoZIhvcNAQELBQAD
        ggIBAKq6LUdMswFjwaRZIRLiN6rMSWEuNrUERHltC3ZY0D0F3YHDAx7pV/8pH+yE
        Rq+uSccHpqZjhqgaS4xhonYQ6j1iXAeojccGcGT49MQ29O/q3EPELRdSEC+iKYTL
        zEfqXHpVL1OcKszHO7o6vuP2DMFqFB9n363GjkyQZE19uZSyX2oVNKvlah6L6wP5
        N/Kc742OMUvwl2iQNTqkrO4EWXmYxIuDsE/DfYLzJo9HLPKVfok4Q+4crv3tHCj5
        BJiFRuVFXeHR8m1LLZRWzSM8uWJJY+/sd4WdRYKh22AsehlLeaKVzFSnH6e4ZRg2
        y/rjnGAllv9m7YPo0c74/KcnEfDK4EkvjwzhRv26yIvOMVvIOs0XmNKxWmtb9PIK
        BhUKdx6uMPRsTEg7sSWB4mnSLlfumc74s4v3LlZAE7w33LVtD0p6Eso+SF5HxEOy
        tmxK/ArJErI1x+WiJ8Wjelz1GGih/a6V1nXaWU9drsa2nP/KaoHNp+pkIBiby0Gd
        0YOBzJkCImEA7qKqrgafCzQzexOCo2MhndqfrZjY98KmU8yxaloTKZYTPponcBn9
        gWE1D/9fB/ob3qCO8hcDHF6hs2ODBCWvhfFWqGgb6JyHC1qUeIpoqH6+plKCYyL6
        um1RkkiU+BReaAts1a86TjDAaXODpmswJ0V39oLAdaGj0wHq
        -----END CERTIFICATE-----
      CERT
    end

    let(:signed_certificate) do
      ::CA::X509::Sign.new(env: env).(
        issuer: issuer,
        certificate_request: certificate_request
      )
    end

    before do
      allow(Resource)
        .to receive(:[])
        .with("rspec:variable:#{private_key_id}")
        .and_return(private_key_variable)

      allow(Resource)
        .to receive(:[])
        .with("rspec:variable:#{cert_chain_id}")
        .and_return(cert_chain_variable)
    end

    context "when all of the inputs are valid" do
      it "returns a signed certificate" do
        expect(signed_certificate).to be_a(::CA::X509::Certificate)
      end
    end
  end
end
