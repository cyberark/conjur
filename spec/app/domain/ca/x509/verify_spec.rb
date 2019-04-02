# frozen_string_literal: true

require 'spec_helper'

describe ::CA::X509::Verify do
  describe '#call' do
    let(:webservice) { ::CA::Webservice.new(resource: ca_resource) }

    let(:certificate_request) do
      ::CA::CertificateRequest.new(kind: kind, params: params, role: role)
    end
  
    let(:kind) { :x509 }

    let(:params) do
      {
        csr: csr
      }
    end

    let(:role) { double("role", kind: "host") }

    let(:env) { double("env") }

    let(:ca_resource) { double("ca_resource") }

    let(:csr) do
      <<~CERT
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
      CERT
    end

    let(:role_annotations) { {} }
    let(:ca_resource_annotations) { {} }

    subject { ::CA::X509::Verify.new(webservice: webservice, env: env).(certificate_request: certificate_request) }

    before do
      allow(webservice).to receive(:service_id)
        .and_return('rspec_ca')

      allow(role).to receive(:annotation).with(anything) do |value|
        role_annotations[value]
      end

      allow(ca_resource).to receive(:annotation).with(anything) do |value|
        ca_resource_annotations[value]
      end
    end

    context "when all of the inputs are valid" do
      before do
        allow(role).to receive(:allowed_to?)
          .with('sign', ca_resource)
          .and_return(true)
      end

      it "returns without error" do
        subject
      end
    end

    context "when a non-existing certificate use is requested" do
      let(:params) do
        {
          csr: csr,
          use: 'foobar'
        }
      end

      it "raises an error" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context "when a CA certificate is requested" do
      let(:params) do
        {
          csr: csr,
          use: 'ca'
        }
      end

      context "and the CA is not permitted to sign CA certificates" do
        it "raises an error" do
          expect { subject }.to raise_error(::Exceptions::Forbidden)
        end
      end

      context "and the CA and user are permitted to sign CA certificates" do
        let(:role_annotations) do
          {
            'ca/ca-use-permitted' => 'true'
          }
        end

        let(:ca_resource_annotations) do
          {
            'ca/ca-use-permitted' => 'true'
          }
        end

        it "does not an error" do
          expect { subject }.not_to raise_error
        end
      end

      context "and the requestor is not permitted to request a CA certificate" do
        it "raises an error" do
          expect { subject }.to raise_error(::Exceptions::Forbidden)
        end
      end

      context "and a path length that exists the configured max is requested" do
        let(:params) do
          {
            csr: csr,
            use: 'ca',
            path_length: 5
          }
        end

        it "raises an error" do
          expect { subject }.to raise_error(::Exceptions::Forbidden)
        end
      end
    end
  end
end
