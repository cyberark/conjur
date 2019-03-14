# frozen_string_literal: true

require 'spec_helper'

describe ::CA::SSH::Sign do
  describe '#sign' do
    let(:certificate_request) do
      ::CA::SSH::CertificateRequest.build(params: params, role: role)
    end
  
    let(:issuer) do
      ::CA::SSH::Issuer.from_resource(ca_resource)
    end

    let(:params) do
      {
        public_key: public_key,
        principals: principals
      }
    end

    let(:role) do
      double("role", 
        account: "rspec", 
        kind: "user", 
        identifier: "alice",
        resource: role_resource) 
    end
    let(:role_resource) { double("role_resource", annotations: [])}

    let(:ca_resource) { double("ca_resource", account: "rspec") }

    let(:ca_resource) do 
      double(
        "ca_resource",
        account: "rspec", 
        identifier: "conjur/ca/ssh",
        annotations: ca_resource_annotations
      )
    end

    let(:ca_resource_annotations) do
      [
        { name: 'ca/max-ttl', value: 'P1D' },
        { name: 'ca/private-key-password', value: private_key_password_id },
        { name: 'ca/private-key', value: private_key_id }
      ]
    end

    let(:env) { double("env") }

    # Generated with `ssh-keygen -t rsa`
    let(:public_key) { "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAklOUpkDHrfHY17SbrmTIpNLTGK9Tjom/BWDSUGPl+nafzlHDTYW7hdI4yZ5ew18JH4JW9jbhUFrviQzM7xlELEVf4h9lFX5QVkbPppSwg0cda3Pbv7kOdJ/MTyBlWXFCR+HAo3FXRitBqxiX1nKhXpHAZsMciLq8V6RjsNAQwdsdMFvSlVK/7XAt3FaoJoAsncM1Q9x5+3V0Ww68/eIFmb1zuUFljQJKprrX88XypNDvjYNby6vw/Pb0rwert/EnmZ+AW4OZPnTPI89ZPmVMLuayrD2cE86Z/il8b+gw3r3+1nKatmIkjn2so1d01QraTlMqVSsbxNrRFi9wrf+M7Q==" }
    
    let(:public_key_format) { nil }
    let(:principals) { double("principals") }

    let(:private_key_variable) do
      double("private_key", secret: double("secret", value: private_key))
    end

    let(:private_key_id) { "conjur/ca/ssh/private-key"}
    let(:private_key_password_id) { nil }

    # Generated with `ssh-keygen -t rsa -m pem`
    let(:private_key) do
      <<~KEY
        -----BEGIN RSA PRIVATE KEY-----
        MIIEpQIBAAKCAQEA1zDDzky9fQiTD/axUia3FYNguKioXE3KnNdtcMiE0+qCQ5ov
        hmEe2Zufd6S0XoSKtv8bonTd/b10buxeAZa620bHl0bQ0+4ReHVWtY3psbB0L/cP
        XbCJbldif4RhAgEKzRyKgH1xqhVPcjVW2dM2ckVaqdMBcYTrzvBQoVskmEmVbI/U
        Q0bNnYcSG/QZ/jY4FIhd2SWyridRibSoFcesJdOg7BMRXtRSb10Lb5DQhhZPHh69
        mI3BCrir3krICL+ZdX84jMaEOZzanAshiF8vHaWodNdnYZSHhgSBWA7QN8LD7cKO
        cYHACUvyp9W/W9XdTZUdOpTgluMPAAP/3txXmQIDAQABAoIBAQDV8i/a/kUu+MVu
        C7EEomVIyFPzhAvPqbAV+8Fdbp9RKkjU+Yjiq9DGPYlwpJqHlnNruXs6K8NCMYh/
        eBWGstuYg2iRKOEatAk+oDrTSwLbnToHLjViys/4mnzdlznziiG5B/VUBmRp28If
        JJTzAKGTPw0C5zz6JlNkbV1c74cUt9DSNHKzFkyHMIF/AfJbBx8zL0W3VnkNljv5
        B+vQOIlFYC9VwNJE5H3lqEVDuVuILJ3JevGQc5glYkYmA7BqgZUsnZAhvGDSo0+K
        7bPL9nRCaZwZA55BBl2W8bBn0Co7Xj4CGkrqgrR01B/kqQ47jr/kzGdEtPlVUfQK
        p8ifNEgBAoGBAPYSgH4REqTYG/nyw5S7vAGr6mhGg4rmYF3ypvvqzxLueFECwGlt
        zGOlMfcke7vXj/XR7lHqvbVU1zohRO1b0Sey88vRfs0Jvc2aye/s/dFHesX61O9D
        ForRsPnHclIa2jR53H7tmqPhs5RWAjc3uGS7P3fUTRiu2O6vZQKxIGsZAoGBAN/f
        TtEGB+/b5T/YRZkErXvi5gsb0ojTAj+WADl3dzKoAjGcpUfriQ6pFA1e3aub2J7Q
        vWjQL6REKRwGLAabmtyqMr0IjU1gnuYZkdn6U07bLmsvPltHQ5HVNs/PyTQWEf0/
        rKW447oxakmOYf+b5106aYav0iAkB2r0OLro5WCBAoGBAKFtF9AcASAVCZ1aDcYX
        tkleb2NCxu6rHRLkqXjf3EJuII38gR9owUmpSHL6AxYCXtWDh5VDqno3kw32X1Jb
        BoXFlrvhzg5SUqp73ffAf+33t2oDmAbx+urMjw39Mlj8dqMwQl8eHnFeEkHAfqmc
        qyGh2QwSQRVtNrC2bUxryHmZAoGBAJfYu3kDgjarDB/17Z8QkStKh4ZZZL/xf8Dp
        WVWhNnRhiLtl6KWTmO8ct8Ep62kO2CtAoniJXQcqREgB17LTsIKj3q5hMpadRqoE
        Be234PHHsQB6lu0KtUYhPIBQC8UMgz8nBU+SzMPp6JHjxYy+jnuptxHoB7pNNcrR
        w/jjJ1IBAoGAX+WGT9+w0c/ylRvQzowWNmbs3f+8el3GJZI83TgpLc1wgHp0dlRO
        HqWDwHkDlp2GDndNPeKxeSyTWWSpaO57uWJ6Rqr2SIEqOIL+vvkRaXiV99d4oL9z
        s8ztzQJ+DCJ0CmLpiE1T7evVCUIKbhuN2R5iAb/+g8KC1GYOCqaj2Bs=
        -----END RSA PRIVATE KEY-----
      KEY
    end

    let(:private_key_password) { nil }

    let(:signed_certificate) do
      ::CA::SSH::Sign.new(env: env).(
        issuer: issuer,
        certificate_request: certificate_request
      )
    end

    before do
      allow(Resource)
        .to receive(:[])
        .with("rspec:variable:#{private_key_id}")
        .and_return(private_key_variable)
    end

    context "when all of the inputs are valid" do
      it "returns a signed certificate" do
        expect(signed_certificate).to be_a(::CA::SSH::Certificate)
      end
    end
  end
end
