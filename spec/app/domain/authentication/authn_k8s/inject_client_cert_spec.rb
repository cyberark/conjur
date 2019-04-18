# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::AuthnK8s::InjectClientCert do
  include_context "running in kubernetes"

  let(:spiffe_name) { "SpiffeName" }
  let(:spiffe_namespace) { "SpiffeNamespace" }

  let(:account) { "SomeAccount" }
  let(:service_id) { "ServiceName" }
  let(:common_name) { "CommonName.#{spiffe_namespace}.Controller.Id" }
  let(:csr) { "CSR" }

  let(:host_id) { "HostId" }
  let(:host_id) { "HostId" }
  let(:host_role) { double("HostRole", id: host_id) }

  let(:k8s_authn_container_name) { 'kubernetes/authentication-container-name' }
  let(:host_annotation_1) { double("Annot1", values: { name: "first" }) }
  let(:host_annotation_2) { double("Annot2") }

  let(:host_annotations) { [ host_annotation_1, host_annotation_2 ] }

  let(:host) { double("Host", role: host_role,
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

  let(:smart_csr) { double("SmartCSR", common_name: common_name,
                                       spiffe_id: spiffe_id) }

  let(:bad_spiffe_smart_csr) { double("SmartCSR", common_name: common_name,
                                                  spiffe_id: nil) }

  let(:bad_cn_namespace_smart_csr) {
    double("SmartCSR",
      common_name: "CommonName.WrongNamespace.Controller.Id",
      spiffe_id: spiffe_id)
  }

  let(:pod_request) { double("PodRequest", k8s_host: k8s_host,
                                           spiffe_id: spiffe_id) }

  let(:validate_pod_request) { double("ValidatePodRequest") }

  let(:dependencies) { { resource_repo: double(),
                         conjur_ca_repo: double(),
                         k8s_object_lookup: double(),
                         kubectl_exec: double(),
                         validate_pod_request: validate_pod_request } }

  before(:each) do
    allow(Resource).to receive(:[])
      .with(host_id)
      .and_return(host)

    allow(Authentication::Webservice).to receive(:new)
      .with(hash_including(
        account: account,
        authenticator_name: 'authn-k8s',
        service_id: service_id))
      .and_return(webservice)

    allow(Repos::ConjurCA).to receive(:ca)
      .with(webservice_resource_id)
      .and_return(ca_for_webservice)

    allow(ca_for_webservice).to receive(:signed_cert)
      .with(csr, hash_including(
        subject_altnames: [ spiffe_altname ]))
      .and_return(webservice_signed_cert)

    allow(webservice_signed_cert).to receive(:to_pem)
      .and_return(webservice_signed_cert_pem)

    allow(Authentication::AuthnK8s::K8sHost)
      .to receive(:from_csr)
      .with(hash_including(account: account,
                           service_name: service_id,
                           csr: csr))
      .and_return(k8s_host)

    allow(Util::OpenSsl::X509::SmartCsr)
      .to receive(:new)
      .with(csr)
      .and_return(smart_csr)

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

    allow(Authentication::AuthnK8s::ValidatePodRequest)
      .to receive(:new)
      .and_return(validate_pod_request)

      allow(host_annotation_2).to receive(:values)
        .and_return({ name: k8s_authn_container_name })
      allow(host_annotation_2).to receive(:[])
        .with(:value)
        .and_return(nil)
  end

  subject(:injector) { Authentication::AuthnK8s::InjectClientCert
    .new(dependencies: dependencies) }

  context "invocation" do
    context "when csr is checked" do
      before :each do
        allow(validate_pod_request)
          .to receive(:call)
          .with(no_args)
          .and_return(nil)
      end

      it "throws CSRIsMissingSpiffeId if smart_csr.spiffe_id is not defined" do
        error_type = Authentication::AuthnK8s::CSRIsMissingSpiffeId
        missing_spiffe_id_error = /CSR must contain SPIFFE ID SAN/

        allow(Util::OpenSsl::X509::SmartCsr)
          .to receive(:new)
          .with(csr)
          .and_return(bad_spiffe_smart_csr)

        expect { injector.(conjur_account: account,
                           service_id: service_id,
                           csr: csr) }.to raise_error(error_type, missing_spiffe_id_error)
      end

      it "throws CSRNamespaceMismatch when common_name does not match spiffe_id.namespace" do
        error_type = Authentication::AuthnK8s::CSRNamespaceMismatch
        wrong_cn_error = /Namespace in SPIFFE ID 'WrongNamespace' must match namespace implied by common name 'SpiffeNamespace'/

        allow(Util::OpenSsl::X509::SmartCsr)
          .to receive(:new)
          .with(csr)
          .and_return(bad_cn_namespace_smart_csr)

        expect { injector.(conjur_account: account,
                           service_id: service_id,
                           csr: csr) }.to raise_error(error_type, wrong_cn_error)
      end
    end

    it "raises RuntimeError when validate_pod_request fails" do
      pod_validation_error = "PodValidationFailed"

      allow(validate_pod_request)
        .to receive(:call)
        .with(no_args)
        .and_raise(pod_validation_error)

      expect { injector.(conjur_account: account,
                         service_id: service_id,
                         csr: csr) }.to raise_error(RuntimeError, pod_validation_error)
    end

    context "when cert is being installed" do
      let (:kubectl_exec_instance) { double("MockKubectlExec") }
      let (:copy_response) { double("MockCopyrespoonse") }

      before :each do
        allow(validate_pod_request)
          .to receive(:call)
          .with(no_args)
          .and_return(nil)

        allow(Authentication::AuthnK8s::KubectlExec)
          .to receive(:new)
          .and_return(kubectl_exec_instance)

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

      it "rethrows if copy operation raises runtime error" do
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
                           csr: csr) }.to raise_error(RuntimeError, expected_error_text)
      end

      it "throws CertInstallationError if copy response error stream is not empty" do
        error_type = Authentication::AuthnK8s::CertInstallationError
        expected_error_text = "ExpectedCopyError"
        expected_full_error_text = /Cert could not be copied to pod: ExpectedCopyError/

        allow(copy_response).to receive(:[])
          .with(:error)
          .and_return(expected_error_text)

        expect { injector.(conjur_account: account,
                           service_id: service_id,
                           csr: csr) }.to raise_error(error_type, expected_full_error_text)
      end

      it "throws CertInstallationError if copy response error stream is just whitespace" do
        error_type = Authentication::AuthnK8s::CertInstallationError
        expected_full_error_text = /Cert could not be copied to pod: The server returned a blank error message/

        allow(copy_response).to receive(:[])
          .with(:error)
          .and_return("\n   \n")

        expect { injector.(conjur_account: account,
                           service_id: service_id,
                           csr: csr) }.to raise_error(error_type, expected_full_error_text)
      end

      context "and is successfully copied" do
        it "throws no errors if copy is sucessful and error stream is nil" do
          expect { injector.(conjur_account: account,
                             service_id: service_id,
                             csr: csr) }.to_not raise_error
        end

        it "throws no errors if copy is sucessful and error stream is empty string" do
          allow(copy_response).to receive(:[])
            .with(:error)
            .and_return("")

          expect { injector.(conjur_account: account,
                             service_id: service_id,
                             csr: csr) }.to_not raise_error
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
                             csr: csr) }.to_not raise_error
        end
      end
    end
  end
end
