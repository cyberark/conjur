# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::AuthnK8s::ValidatePodRequest do
  include_context "running outside kubernetes"

  let(:error_template) { "An error occured" }

  let(:account) { "SomeAccount" }

  let(:host_id) { "HostId" }
  let(:host_role) { double("HostRole", :id => host_id) }

  let(:host_annotation_1) { double("Annot1", :values => { :name => "first" }) }
  let(:host_annotation_2) { double("Annot2") }

  let(:host_annotations) { [host_annotation_1, host_annotation_2] }

  let(:host) { double("Host", :role => host_role,
                      :annotations  => host_annotations) }

  let(:k8s_host_object) { "K8sHostObject" }
  let(:k8s_host_namespace) { "K8sHostNamespace" }
  let(:k8s_host) { double("K8sHost", :account => account,
                          :conjur_host_id     => host_id) }

  let(:bad_service_name) { "BadMockService" }
  let(:good_service_id) { "MockService" }

  let(:good_webservice) { Authentication::Webservice.new(
    account:            account,
    authenticator_name: 'authn-k8s',
    service_id:         good_service_id
  ) }

  let(:spiffe_name) { "SpiffeName" }
  let(:spiffe_namespace) { "SpiffeNamespace" }
  let(:spiffe_id) { double("SpiffeId", :name => spiffe_name,
                           :namespace        => spiffe_namespace) }
  let(:pod_request) { double("PodRequest", :k8s_host => k8s_host,
                             :spiffe_id              => spiffe_id) }
  let(:pod_spec) { double("PodSpec") }
  let(:pod) { double("Pod", :spec => pod_spec) }
  
  let(:k8s_object_lookup_class) { double("K8sObjectLookup") }

  let(:validate_application_identity) { double("ValidateApplicationIdentity") }

  let(:dependencies) { { resource_class:             double(),
                         k8s_object_lookup_class:   k8s_object_lookup_class,
                         validate_application_identity: validate_application_identity } }

  before(:each) do
    allow(Resource).to receive(:[])
                         .with(host_id)
                         .and_return(host)

    allow(Resource).to receive(:[])
                         .with("#{account}:webservice:conjur/authn-k8s/#{good_service_id}")
                         .and_return(good_webservice)
    allow(Resource).to receive(:[])
                         .with("#{account}:webservice:conjur/authn-k8s/#{bad_service_name}")
                         .and_return(nil)

    allow(pod_request).to receive(:service_id).and_return(good_service_id)
    allow(host_role).to receive(:allowed_to?)
                          .with("authenticate", good_webservice)
                          .and_return(true)

    allow(k8s_object_lookup_class).to receive(:pod_by_name)
                                        .with(spiffe_name, spiffe_namespace)
                                        .and_return(pod)

    allow(Authentication::AuthnK8s::K8sObjectLookup)
      .to receive(:new)
            .and_return(k8s_object_lookup_class)

    allow(Authentication::AuthnK8s::ValidateApplicationIdentity)
      .to receive(:new)
            .and_return(validate_application_identity)
    allow(validate_application_identity).to receive(:call)
                                          .and_return(true)
  end

  context "invocation" do
    subject(:validator) { Authentication::AuthnK8s::ValidatePodRequest
                            .new(dependencies: dependencies) }

    it 'raises WebserviceNotFound error when webservice is missing' do
      allow(pod_request).to receive(:service_id).and_return(bad_service_name)

      expected_message = /Webservice '#{bad_service_name}' wasn't found/
      expect { validator.(pod_request: pod_request) }
        .to raise_error(Errors::Authentication::AuthnK8s::WebserviceNotFound, expected_message)
    end

    it 'raises HostNotAuthorized when host is not allowed to authenticate to service' do
      allow(pod_request).to receive(:service_id).and_return(good_service_id)
      allow(host_role).to receive(:allowed_to?)
                            .with("authenticate", good_webservice)
                            .and_return(false)

      expected_message = /'#{host_id}' does not have 'authenticate' privilege on #{good_service_id}/

      expect { validator.(pod_request: pod_request) }
        .to raise_error(Errors::Authentication::AuthnK8s::HostNotAuthorized, expected_message)
    end

    it 'raises PodNotFound when pod is not known' do
      allow(pod_request).to receive(:service_id).and_return(good_service_id)
      allow(host_role).to receive(:allowed_to?)
                            .with("authenticate", good_webservice)
                            .and_return(true)
      allow(k8s_object_lookup_class).to receive(:pod_by_name)
                                          .with(spiffe_name, spiffe_namespace)
                                          .and_return(nil)

      expected_message = /CONJ00024E.*'#{spiffe_name}'.*'#{spiffe_namespace}'/

      expect { validator.(pod_request: pod_request) }
        .to raise_error(Errors::Authentication::AuthnK8s::PodNotFound, expected_message)
    end

    it 'raises an error when application identity validation fails' do
      allow(validate_application_identity).to receive(:call)
                                            .and_raise('FAKE_application_identity_ERROR')

      expect { validator.(pod_request: pod_request) }
        .to raise_error(/FAKE_application_identity_ERROR/)
    end
  end
end
