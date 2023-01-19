# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::AuthnK8s::ValidatePodRequest do
  include_context "running outside kubernetes"
  include_context "security mocks"

  let(:account) { "SomeAccount" }

  let(:host_id) { "HostId" }
  let(:host_name) { "HostName" }
  let(:host_role) { double("HostRole", :id => host_id) }
  let(:k8s_authn_container_name) { 'kubernetes/authentication-container-name' }

  let(:host_annotation_1) { double("Annot1", :values => { :name => "first" }) }
  let(:host_annotation_2) { double("Annot2") }

  let(:host_annotations) { [host_annotation_1, host_annotation_2] }

  let(:host) { double("Host", :role => host_role,
    :annotations                    => host_annotations) }

  let(:k8s_host) {
    double(
      "K8sHost",
      :account        => account,
      :conjur_host_id => host_id,
      :k8s_host_name  => host_name
    )
  }

  let(:resource_class) { double("Resource") }

  let(:service_id) { "MockService" }

  let(:authenticator_name) { 'authn-k8s' }

  let(:spiffe_name) { "SpiffeName" }
  let(:spiffe_namespace) { "SpiffeNamespace" }
  let(:spiffe_id) { double("SpiffeId", :name => spiffe_name,
    :namespace                               => spiffe_namespace) }
  let(:pod_request) { double("PodRequest", :k8s_host => k8s_host,
    :spiffe_id                                       => spiffe_id) }
  let(:pod_spec) { double("PodSpec") }
  let(:pod) { double("Pod", :spec => pod_spec) }

  let(:k8s_object_lookup_class) { double("K8sObjectLookup") }

  let(:validate_resource_restrictions) { double("ValidateResourceRestrictions") }

  before(:each) do
    allow(resource_class).to receive(:[])
                               .with(host_id)
                               .and_return(host)

    allow(pod_request).to receive(:service_id).and_return(service_id)

    allow(k8s_object_lookup_class).to receive(:pod_by_name)
                                        .with(spiffe_name, spiffe_namespace)
                                        .and_return(pod)

    allow(k8s_object_lookup_class).to receive(:new)
                                        .and_return(k8s_object_lookup_class)

    allow(Authentication::AuthnK8s::ValidateResourceRestrictions)
      .to receive(:new)
            .and_return(validate_resource_restrictions)
    allow(validate_resource_restrictions).to receive(:call)
                                              .and_return(true)
  end

  context "A ValidatePodRequest invocation" do
    context "that passes webservice validations" do
      subject do
        Authentication::AuthnK8s::ValidatePodRequest.new(
          resource_class:                      resource_class,
          k8s_object_lookup_class:             k8s_object_lookup_class,
          validate_role_can_access_webservice: mock_validate_role_can_access_webservice(validation_succeeded: true),
          validate_webservice_is_whitelisted:  mock_validate_webservice_is_whitelisted(validation_succeeded: true),
          enabled_authenticators:              "#{authenticator_name}/#{service_id}",
          validate_resource_restrictions:      validate_resource_restrictions
        ).call(
          pod_request: pod_request
        )
      end

      it 'raises PodNotFound when pod is not known' do
        allow(k8s_object_lookup_class).to receive(:pod_by_name)
                                            .with(spiffe_name, spiffe_namespace)
                                            .and_return(nil)

        expect { subject }.to(
          raise_error(
            ::Errors::Authentication::AuthnK8s::PodNotFound
          )
        )
      end

      it 'raises an error when resource restrictions validation fails' do
        allow(validate_resource_restrictions).to receive(:call)
                                                   .and_raise('FAKE_RESOURCE_RESTRICTIONS_ERROR')

        expect { subject }.to(
          raise_error(
            /FAKE_RESOURCE_RESTRICTIONS_ERROR/
          )
        )
      end

      it 'raises ContainerNotFound if container cannot be found and container name is defaulted' do
        allow(pod_spec).to receive(:initContainers)
                             .and_return({})
        allow(pod_spec).to receive(:containers)
                             .and_return({})
        allow(host_annotation_2).to receive(:values)
                                      .and_return({ :name => k8s_authn_container_name })
        allow(host_annotation_2).to receive(:[])
                                      .with(:value)
                                      .and_return(nil)

        expect { subject }
          .to raise_error(Errors::Authentication::AuthnK8s::ContainerNotFound)
      end

      it 'raises ContainerNotFound if container cannot be found and container name annotation is missing' do
        allow(pod_spec).to receive(:initContainers)
                             .and_return({})
        allow(pod_spec).to receive(:containers)
                             .and_return({})
        allow(host_annotation_2).to receive(:values)
                                      .and_return({ :name => "notimportant" })

        expect { subject }
          .to raise_error(Errors::Authentication::AuthnK8s::ContainerNotFound)
      end
    end

    context "with an inaccessible webservice" do
      subject do
        Authentication::AuthnK8s::ValidatePodRequest.new(
          resource_class:                      resource_class,
          k8s_object_lookup_class:             k8s_object_lookup_class,
          validate_role_can_access_webservice: mock_validate_role_can_access_webservice(validation_succeeded: false),
          validate_webservice_is_whitelisted:  mock_validate_webservice_is_whitelisted(validation_succeeded: true),
          enabled_authenticators:              "#{authenticator_name}/#{service_id}",
          validate_resource_restrictions:      validate_resource_restrictions
        ).call(
          pod_request: pod_request
        )
      end

      it 'raises an error' do
        expect { subject }.to(
          raise_error(
            validate_role_can_access_webservice_error
          )
        )
      end
    end

    context "with a non-whitelisted webservice" do
      subject do
        Authentication::AuthnK8s::ValidatePodRequest.new(
          resource_class:                      resource_class,
          k8s_object_lookup_class:             k8s_object_lookup_class,
          validate_role_can_access_webservice: mock_validate_role_can_access_webservice(validation_succeeded: true),
          validate_webservice_is_whitelisted:  mock_validate_webservice_is_whitelisted(validation_succeeded: false),
          enabled_authenticators:              "#{authenticator_name}/#{service_id}",
          validate_resource_restrictions:      validate_resource_restrictions
        ).call(
          pod_request: pod_request
        )
      end

      it 'raises an error' do
        expect { subject }.to(
          raise_error(
            validate_webservice_is_whitelisted_error
          )
        )
      end
    end

    context "with a non-existing user" do
      subject do
        Authentication::AuthnK8s::ValidatePodRequest.new(
          resource_class:                      resource_class,
          k8s_object_lookup_class:             k8s_object_lookup_class,
          validate_role_can_access_webservice: mock_validate_role_can_access_webservice(validation_succeeded: true),
          validate_webservice_is_whitelisted:  mock_validate_webservice_is_whitelisted(validation_succeeded: true),
          enabled_authenticators:              "#{authenticator_name}/#{service_id}",
          validate_resource_restrictions:      validate_resource_restrictions
        ).call(
          pod_request: pod_request
        )
      end

      it 'raises an error' do
        allow(resource_class).to receive(:[])
                                   .with(host_id)
                                   .and_return(nil)

        expect { subject }.to(
          raise_error(
            Errors::Authentication::Security::RoleNotFound
          )
        )
      end
    end
  end
end
