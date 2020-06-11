# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::AuthnK8s::InjectClientCert do
  include_context "running in kubernetes"

  let(:spiffe_name) { "SpiffeName" }
  let(:spiffe_namespace) { "SpiffeNamespace" }

  let(:account) { "SomeAccount" }
  let(:service_id) { "ServiceName" }
  let(:common_name) { "CommonName.#{spiffe_namespace}.Resource.Id" }
  let(:host_id_prefix) { "host.some-policy" }
  let(:nil_host_id_prefix) { nil }
  let(:csr) { "CSR" }

  let(:host_id) { "HostId" }
  let(:host_role) { double("HostRole", id: host_id) }

  let(:k8s_authn_container_name) { 'kubernetes/authentication-container-name' }
  let(:host_annotation_1) { double("Annot1", values: { name: "first" }) }
  let(:host_annotation_2) { double("Annot2") }

  let(:host_annotations) { [ host_annotation_1, host_annotation_2 ] }

  let(:host) { double("Host", role: host_role,
                              identifier: host_id,
                              annotations: host_annotations) }

  let(:webservice_resource_id) { "MockWebserviceResourceId" }
  let(:webservice_signed_cert) { double("MockWebserviceSignedCert") }
  let(:webservice_signed_cert_pem) { "MockWebserviceSignedCertPem" }
  let(:webservice) { double("MockWebservice", resource_id: webservice_resource_id) }
  let(:ca_for_webservice) { double("MockCAForWebservice") }

  let(:k8s_host) { double("K8sHost", account: account,
                                     conjur_host_id: host_id) }

  let(:spiffe_altname) { "SpiffeAltname" }
  let(:spiffe_id) { double("SpiffeId", name: spiffe_name,
                                       namespace: spiffe_namespace,
                                       to_altname: spiffe_altname) }

  let(:smart_csr_mock) { double("SmartCSR", common_name: common_name,
                                       spiffe_id: spiffe_id) }

  let(:bad_spiffe_smart_csr_mock) { double("SmartCSR", common_name: common_name,
                                                  spiffe_id: nil) }

  let(:bad_cn_namespace_smart_csr_mock) {
    double("SmartCSR",
      common_name: "CommonName.WrongNamespace.Resource.Id",
      spiffe_id: spiffe_id)
  }

  let(:pod_request) { double("PodRequest", k8s_host: k8s_host,
                                           spiffe_id: spiffe_id) }

  let(:kubectl_exec_instance) { double("MockKubectlExec") }
  let(:kubectl_exec) do
    double('kubectl_exec').tap do |kubectl_exec|
      allow(kubectl_exec).to receive(:new)
        .with(no_args)
        .and_return(kubectl_exec_instance)
    end
  end

  let(:resource_class) do
    double(Resource).tap do |resource_class|
      allow(resource_class).to receive(:[])
      .with(host_id)
      .and_return(host)
    end
  end

  let(:conjur_ca_repo) do
    double(Repos::ConjurCA).tap do |conjur_ca_repo|
      allow(conjur_ca_repo).to receive(:ca)
      .with(webservice_resource_id)
      .and_return(ca_for_webservice)
    end
  end

  let(:validate_pod_request) { double("ValidatePodRequest") }

  let(:dependencies) { { resource_class: resource_class,
                         conjur_ca_repo: conjur_ca_repo,
                         kubectl_exec: kubectl_exec,
                         validate_pod_request: validate_pod_request,
                         audit_log: audit_logger} }

  let(:audit_success) { true }
  let(:audit_logger) do
    double('audit_logger').tap do |logger|
      expect(logger).to receive(:log)
    end
  end

  before(:each) do

    allow(Authentication::Webservice).to receive(:new)
      .with(hash_including(
        account: account,
        authenticator_name: 'authn-k8s',
        service_id: service_id))
      .and_return(webservice)

    allow(ca_for_webservice).to receive(:signed_cert)
      .with(smart_csr_mock, hash_including(
        subject_altnames: [ spiffe_altname ]))
      .and_return(webservice_signed_cert)

    allow(webservice_signed_cert).to receive(:to_pem)
      .and_return(webservice_signed_cert_pem)

    allow(Authentication::AuthnK8s::K8sHost)
      .to receive(:from_csr)
      .with(hash_including(account: account,
                           service_name: service_id,
                           csr: anything))
      .and_return(k8s_host)

    allow(Util::OpenSsl::X509::SmartCsr)
      .to receive(:new)
      .with(csr)
      .and_return(smart_csr_mock)

    allow(Authentication::AuthnK8s::SpiffeId)
      .to receive(:new)
      .with(spiffe_id)
      .and_return(spiffe_id)

    allow(Authentication::AuthnK8s::PodRequest)
      .to receive(:new)
      .with(hash_including(service_id: service_id,
                           k8s_host: k8s_host,
                           spiffe_id: spiffe_id))
      .and_return(pod_request)

      allow(host_annotation_2).to receive(:values)
        .and_return({ name: k8s_authn_container_name })
      allow(host_annotation_2).to receive(:[])
        .with(:value)
        .and_return(nil)

    allow(smart_csr_mock).to receive(:common_name=)
  end

  subject(:injector) do
     Authentication::AuthnK8s::InjectClientCert.new(**dependencies)
  end

  context "invocation" do
    context "when csr is checked" do
      before :each do
        allow(validate_pod_request)
          .to receive(:call)
          .with(no_args)
          .and_return(nil)
      end

      context "when smart_csr.spiffe_id is not defined" do
        let(:audit_success) { false }
        it "throws CSRIsMissingSpiffeId" do
          error_type = Errors::Authentication::AuthnK8s::CSRIsMissingSpiffeId
          missing_spiffe_id_error = /CSR must contain SPIFFE ID SAN/

          allow(Util::OpenSsl::X509::SmartCsr)
            .to receive(:new)
            .with(csr)
            .and_return(bad_spiffe_smart_csr_mock)
          allow(bad_spiffe_smart_csr_mock).to receive(:common_name=)

          expect { injector.(conjur_account: account,
                            service_id: service_id,
                            csr: csr,
                            host_id_prefix: host_id_prefix) }.to raise_error(error_type, missing_spiffe_id_error)
        end
      end
    end

    context "when validate_pod_request fails" do
      let(:audit_success) { false }

      it "raises RuntimeError" do
        pod_validation_error = "PodValidationFailed"

        allow(validate_pod_request)
          .to receive(:call)
          .with(hash_including(pod_request: anything))
          .and_raise(pod_validation_error)

        expect { injector.(conjur_account: account,
                          service_id: service_id,
                          csr: csr,
                          host_id_prefix: host_id_prefix) }.to raise_error(RuntimeError, pod_validation_error)
      end
    end

    context "when cert is being installed" do
      let (:copy_response) { double("MockCopyrespoonse") }

      before :each do
        allow(validate_pod_request)
          .to receive(:call)
          .with(hash_including(pod_request: anything))
          .and_return(nil)

        allow(copy_response).to receive(:[])
          .with(:error)
          .and_return(nil)

        allow(kubectl_exec_instance).to receive(:copy)
          .with(hash_including(
            pod_namespace: spiffe_namespace,
            pod_name: spiffe_name,
            container: 'authenticator',
            path: "/etc/conjur/ssl/client.pem",
            content: webservice_signed_cert_pem,
            mode: 0o644))
          .and_return(copy_response)
      end

      context "when copy operation raises runtime error" do
        let(:audit_success) { false }
        
        it "rethrows" do
          expected_error_text = "ExpectedCopyError"

          allow(kubectl_exec_instance).to receive(:copy)
            .with(hash_including(
              pod_namespace: spiffe_namespace,
              pod_name: spiffe_name,
              path: "/etc/conjur/ssl/client.pem",
              content: webservice_signed_cert_pem,
              mode: 0o644))
            .and_raise(RuntimeError.new(expected_error_text))

          expect { injector.(conjur_account: account,
                            service_id: service_id,
                            csr: csr,
                            host_id_prefix: host_id_prefix) }.to raise_error(RuntimeError, expected_error_text)
        end
      end

      context "when copy response error stream is not empty" do
        let(:audit_success) { false}

        it "throws CertInstallationError" do
          error_type = Errors::Authentication::AuthnK8s::CertInstallationError
          expected_error_text = "ExpectedCopyError"
          expected_full_error_text = /CONJ00027E.*ExpectedCopyError/

          allow(copy_response).to receive(:[])
            .with(:error)
            .and_return(expected_error_text)

          expect { injector.(conjur_account: account,
                            service_id: service_id,
                            csr: csr,
                            host_id_prefix: host_id_prefix) }.to raise_error(error_type, expected_full_error_text)
        end
      end

      context "when copy response error stream is just whitespace" do
        let(:audit_success) { false }

        it "throws CertInstallationError" do
          error_type = Errors::Authentication::AuthnK8s::CertInstallationError
          expected_full_error_text = /CONJ00027E.*The server returned a blank error message/

          allow(copy_response).to receive(:[])
            .with(:error)
            .and_return("\n   \n")

          expect { injector.(conjur_account: account,
                            service_id: service_id,
                            csr: csr,
                            host_id_prefix: host_id_prefix) }.to raise_error(error_type, expected_full_error_text)
        end
      end

      context "and is successfully copied" do
        it "throws no errors if copy is successful and error stream is nil" do
          expect { injector.(conjur_account: account,
                             service_id: service_id,
                             csr: csr,
                             host_id_prefix: host_id_prefix) }.to_not raise_error
        end

        it "throws no errors if copy is successful and error stream is empty string" do
          allow(copy_response).to receive(:[])
            .with(:error)
            .and_return("")

          expect { injector.(conjur_account: account,
                             service_id: service_id,
                             csr: csr,
                             host_id_prefix: host_id_prefix) }.to_not raise_error
        end

        it "uses policy-defined container name if set" do
          RSpec::Mocks.space.proxy_for(kubectl_exec_instance).reset

          overridden_container_name = "ContainerName"

          allow(host_annotation_2).to receive(:[])
            .with(:value)
            .and_return(overridden_container_name)

          allow(kubectl_exec_instance).to receive(:copy)
            .with(hash_including(
              pod_namespace: spiffe_namespace,
              pod_name: spiffe_name,
              container: overridden_container_name,
              path: "/etc/conjur/ssl/client.pem",
              content: webservice_signed_cert_pem,
              mode: 0o644))
          .and_return(copy_response)

          expect { injector.(conjur_account: account,
                             service_id: service_id,
                             csr: csr,
                             host_id_prefix: host_id_prefix) }.to_not raise_error
        end

        context "when the Host-Id-Prefix parameter doesn't exist" do
          subject do
            injector.(conjur_account: account,
              service_id: service_id,
              csr: csr,
              host_id_prefix: nil_host_id_prefix)
          end

          it "updates the common-name to the hard coded prefix and raises no error" do
            expect(smart_csr_mock).to receive(:common_name=)
                                        .with("host.conjur.authn-k8s.#{service_id}.apps.#{common_name}")
            expect{ subject }.to_not raise_error
          end
        end

        context "when the Host-Id-Prefix parameter exists" do
          subject do
            injector.(conjur_account: account,
              service_id: service_id,
              csr: csr,
              host_id_prefix: host_id_prefix)
          end

          it "updates the common-name to the value of Host-Id-Prefix and raises no error" do
            expect(smart_csr_mock).to receive(:common_name=)
                                        .with("#{host_id_prefix}.#{common_name}")
            expect{ subject }.to_not raise_error
          end
        end
      end
    end
  end
end
