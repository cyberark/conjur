# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::AuthnK8s::ValidateResourceRestrictions do
  include_context "running outside kubernetes"

  let(:account) { "SomeAccount" }

  let(:host_id) { "account_name:kind:HostId" }
  let(:host_role) { double("HostRole", :id => host_id) }

  let(:k8s_authn_container_name) { 'kubernetes/authentication-container-name' }

  let(:host_annotation_1) { double("Annot1", :values => { :name => "first" }) }
  let(:host_annotation_2) { double("Annot2") }
  let(:host_annotations) { [host_annotation_1, host_annotation_2] }

  let(:host) { double("Host", :role => host_role,
                      :annotations  => host_annotations) }

  let(:k8s_host_namespace) { "SpiffeNamespace" }
  let(:k8s_host) { double("K8sHost", :account => account,
                          :conjur_host_id     => host_id) }

  let(:container_name) { "ContainerName" }
  let(:default_container_name) { 'authenticator' }

  let(:bad_service_name) { "BadMockService" }
  let(:good_service_id) { "MockService" }

  let(:good_webservice) { Authentication::Webservice.new(
    account:            account,
    authenticator_name: 'authn-k8s',
    service_id:         good_service_id
  ) }

  let(:k8s_resource_name) { "K8sResourceName" }
  let(:k8s_resource_value) { "K8sResourceValue" }
  let(:k8s_resource_name_2) { "K8sResourceName2" }
  let(:k8s_resource_value_2) { "K8sResourceValue2" }

  let(:no_constraints) { {} }
  let(:one_constraint_list) { [[k8s_resource_name, k8s_resource_value]] }
  let(:two_constraints_list) { [[k8s_resource_name, k8s_resource_value], [k8s_resource_name_2, k8s_resource_value_2]] }

  let(:spiffe_name) { "SpiffeName" }
  let(:spiffe_namespace) { "SpiffeNamespace" }
  let(:spiffe_id) { double("SpiffeId", :name => spiffe_name,
                           :namespace        => spiffe_namespace) }
  let(:pod_spec) { double("PodSpec") }
  let(:pod) { double("Pod", :spec => pod_spec) }
  let(:pod_request) { double("PodRequest", :k8s_host => k8s_host,
                             :spiffe_id              => spiffe_id) }
  let(:k8s_resolver) { double("K8sResolver") }

  let(:k8s_object_lookup_class) { double("K8sObjectLookup") }

  let(:k8s_resolver_for_resource) { double("K8sResolverForResource") }
  let(:k8s_resource) { double("K8sResource") }
  let(:k8s_instantiated_resource) { double("K8sHostInstantiatedResource") }

  let(:resource_restrictions_class) { double("ResourceRestrictions") }
  let(:invalid_configuration_error) { 'INVALID_CONFIGURATION_ERROR' }

  let(:resource_restrictions) {
    [
      Authentication::AuthnK8s::K8sResource.new(
        type: "namespace",
        value: spiffe_namespace
      ),
      Authentication::AuthnK8s::K8sResource.new(
        type: k8s_resource_name,
        value: k8s_resource_value
      )
    ]
  }
  
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

    allow(k8s_object_lookup_class)
      .to receive(:new)
            .and_return(k8s_object_lookup_class)

    allow(k8s_object_lookup_class).to receive(:pod_by_name)
                                        .with(spiffe_name, spiffe_namespace)
                                        .and_return(pod)

    allow(k8s_object_lookup_class).to receive(:find_object_by_name)
                                        .with(k8s_resource_name, k8s_resource_value, k8s_host_namespace)
                                        .and_return(k8s_resource)
    allow(k8s_resolver).to receive(:for_resource)
                                                      .with(k8s_resource_name)
                                                      .and_return(k8s_resolver_for_resource)
    allow(k8s_resolver_for_resource).to receive(:new)
                                          .with(k8s_resource, pod, k8s_object_lookup_class)
                                          .and_return(k8s_instantiated_resource)
    allow(k8s_instantiated_resource).to receive(:validate_pod)
                                          .and_return(false)

    allow(resource_restrictions_class).to receive(:new)
                                            .and_return(resource_restrictions_class)

    allow(resource_restrictions_class).to receive(:resources)
                                            .and_return(resource_restrictions)
  end

  context "Resource restrictions" do
    context "with valid configuration" do
      subject do
        Authentication::AuthnK8s::ValidateResourceRestrictions.new(
          resource_class:              double(),
          k8s_object_lookup_class:     k8s_object_lookup_class,
          k8s_resolver:                k8s_resolver,
          resource_restrictions_class: resource_restrictions_class
        ).call(
          host_id: host_id,
          host_annotations: host_annotations,
          service_id: good_service_id,
          account: account,
          spiffe_id: spiffe_id
        )
      end

      context "that matches request" do
        it "does not raise an error" do
          expect { subject }.to_not raise_error
        end
      end

      context "that does not match request" do
        context "when resource restrictions namespace doesn't match the spiffe id namespace" do
          let(:spiffe_id) {
            double(
              "SpiffeId",
              :name => spiffe_name,
              :namespace => "WrongNamespace"
            )
          }

          it "raises a NamespaceMismatch error" do
            expect { subject }
              .to raise_error(Errors::Authentication::AuthnK8s::NamespaceMismatch)
          end
        end

        context "when the resource in the resource restrictions is not found" do
          before(:each) do
            allow(k8s_object_lookup_class).to receive(:find_object_by_name)
                                                .with(k8s_resource_name, k8s_resource_value, k8s_host_namespace)
                                                .and_return(nil)
          end

          it "raises K8sResourceNotFound" do
            expect { subject }
              .to raise_error(Errors::Authentication::AuthnK8s::K8sResourceNotFound)
          end
        end

        context 'when the resource in the resource restrictions is found' do
          it 'raises error if pod metadata fails validation' do
            validation_error_message = "PodValidationFailed"
            allow(k8s_object_lookup_class)
              .to receive(:find_object_by_name)
                    .with(k8s_resource_name, k8s_resource_value, k8s_host_namespace)
                    .and_raise(validation_error_message)

            expect { subject }.to raise_error(RuntimeError,
              validation_error_message)
          end
        end
      end
    end
  end
end
