# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::AuthnK8s::ValidateResourceRestrictions do
  include_context "running outside kubernetes"

  let(:k8s_resolver) { double("K8sResolver") }

  let(:account) { "SomeAccount" }

  let(:host_id) { "HostId" }
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

  let(:k8s_object_lookup_class) { double("K8sObjectLookup") }

  let(:resource_restrictions_class) { double("ResourceRestrictions") }

  let(:dependencies) { { resource_class:              double(),
                         k8s_object_lookup_class:     k8s_object_lookup_class,
                         k8s_resolver:                k8s_resolver,
                         resource_restrictions_class: resource_restrictions_class } }

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

    allow(Authentication::AuthnK8s::K8sObjectLookup)
      .to receive(:new)
            .and_return(k8s_object_lookup_class)

    allow(Authentication::AuthnK8s::ResourceRestrictions)
      .to receive(:new)
            .and_return(resource_restrictions_class)

    allow(pod_request).to receive(:service_id).and_return(good_service_id)
    allow(host_role).to receive(:allowed_to?)
                          .with("authenticate", good_webservice)
                          .and_return(true)
    allow(k8s_object_lookup_class).to receive(:pod_by_name)
                                        .with(spiffe_name, spiffe_namespace)
                                        .and_return(pod)
    allow(resource_restrictions_class).to receive(:container_name)
                                       .and_return(default_container_name)
    allow(resource_restrictions_class).to receive(:constraints)
                                       .and_return(no_constraints)
    allow(resource_restrictions_class).to receive(:namespace)
                                       .and_return(k8s_host_namespace)
  end

  context "invocation" do
    subject(:validator) { Authentication::AuthnK8s::ValidateResourceRestrictions
                            .new(dependencies: dependencies) }

    context "when resource restrictions namespace doesn't match the spiffe id namespace" do
      before(:each) do
        allow(resource_restrictions_class).to receive(:namespace)
                                           .and_return("WrongNamespace")
      end

      it "raises a NamespaceMismatch error" do
        expected_message = /Namespace in SPIFFE ID 'SpiffeNamespace' must match namespace implied by resource restriction 'WrongNamespace'/
        expect { validator.(
          host_id: host_id,
            host_annotations: host_annotations,
            service_id: good_service_id,
            account: account,
            spiffe_id: spiffe_id
        ) }
          .to raise_error(Errors::Authentication::AuthnK8s::NamespaceMismatch, expected_message)
      end
    end

    context 'when namespace scoped' do
      before(:each) do
        allow(resource_restrictions_class).to receive(:namespace_scoped?)
                                           .and_return(true)
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

        expected_message = /Container authenticator was not found in the pod/
        expect { validator.(
          host_id: host_id,
            host_annotations: host_annotations,
            service_id: good_service_id,
            account: account,
            spiffe_id: spiffe_id
        ) }
          .to raise_error(Errors::Authentication::AuthnK8s::ContainerNotFound, expected_message)
      end

      it 'raises ContainerNotFound if container cannot be found and container name annotation is missing' do
        allow(pod_spec).to receive(:initContainers)
                             .and_return({})
        allow(pod_spec).to receive(:containers)
                             .and_return({})
        allow(host_annotation_2).to receive(:values)
                                      .and_return({ :name => "notimportant" })

        expected_message = /Container authenticator was not found in the pod/
        expect { validator.(
          host_id: host_id,
            host_annotations: host_annotations,
            service_id: good_service_id,
            account: account,
            spiffe_id: spiffe_id
        ) }
          .to raise_error(Errors::Authentication::AuthnK8s::ContainerNotFound, expected_message)
      end

      it 'raises ContainerNotFound if initContainers is nil' do
        allow(pod_spec).to receive(:initContainers)
                             .and_return({})
        allow(pod_spec).to receive(:containers)
                             .and_return(nil)
        allow(host_annotation_2).to receive(:values)
                                      .and_return({ :name => "notimportant" })

        expected_message = /Container authenticator was not found in the pod/
        expect { validator.(
          host_id: host_id,
            host_annotations: host_annotations,
            service_id: good_service_id,
            account: account,
            spiffe_id: spiffe_id
        ) }
          .to raise_error(Errors::Authentication::AuthnK8s::ContainerNotFound, expected_message)
      end

      it 'raises ContainerNotFound if containers is nil' do
        allow(pod_spec).to receive(:initContainers)
                             .and_return(nil)
        allow(pod_spec).to receive(:containers)
                             .and_return({})
        allow(host_annotation_2).to receive(:values)
                                      .and_return({ :name => "notimportant" })

        expected_message = /Container authenticator was not found in the pod/
        expect { validator.(
          host_id: host_id,
            host_annotations: host_annotations,
            service_id: good_service_id,
            account: account,
            spiffe_id: spiffe_id
        ) }
          .to raise_error(Errors::Authentication::AuthnK8s::ContainerNotFound, expected_message)
      end

      it 'does not raise errors if all checks pass' do
        allow(pod_spec).to receive(:initContainers)
                             .and_return({})
        allow(pod_spec).to receive(:containers)
                             .and_return([double("Container1", :name => "notimportant"),
                                          double("Container2", :name => container_name)])
        allow(host_annotation_2).to receive(:values)
                                      .and_return({ :name => k8s_authn_container_name })
        allow(host_annotation_2).to receive(:[])
                                      .with(:value)
                                      .and_return(container_name)
        allow(resource_restrictions_class).to receive(:container_name)
                                           .and_return(container_name)

        expect { validator.(
          host_id: host_id,
            host_annotations: host_annotations,
            service_id: good_service_id,
            account: account,
            spiffe_id: spiffe_id
        ) }.to_not raise_error
      end
    end

    context 'when not namespace scoped' do
      let(:k8s_resolver_for_resource) { double("K8sResolverForResource") }
      let(:k8s_resource) { double("K8sResource") }
      let(:k8s_instantiated_resource) { double("K8sHostInstantiatedResource") }

      before(:each) do
        allow(resource_restrictions_class).to receive(:namespace_scoped?)
                                           .and_return(false)
        allow(resource_restrictions_class).to receive(:constraints)
                                           .and_return(one_constraint_list)
      end

      context "when the resource in the resource restrictions is not found" do
        before(:each) do
          allow(k8s_object_lookup_class).to receive(:find_object_by_name)
                                              .with(k8s_resource_name, k8s_resource_value, k8s_host_namespace)
                                              .and_return(nil)
        end

        it "raises K8sResourceNotFound" do
          expected_message = /Kubernetes K8sResourceName K8sResourceValue not found in namespace SpiffeNamespace/
          expect { validator.(
            host_id: host_id,
              host_annotations: host_annotations,
              service_id: good_service_id,
              account: account,
              spiffe_id: spiffe_id
          ) }
            .to raise_error(Errors::Authentication::AuthnK8s::K8sResourceNotFound, expected_message)
        end
      end

      context 'when the resource in the resource restrictions is found' do
        before(:each) do
          allow(k8s_object_lookup_class).to receive(:find_object_by_name)
                                              .with(k8s_resource_name, k8s_resource_value, k8s_host_namespace)
                                              .and_return(k8s_resource)
          allow(Authentication::AuthnK8s::K8sResolver).to receive(:for_resource)
                                                            .with(k8s_resource_name)
                                                            .and_return(k8s_resolver_for_resource)
          allow(k8s_resolver_for_resource).to receive(:new)
                                                .with(k8s_resource, pod, k8s_object_lookup_class)
                                                .and_return(k8s_instantiated_resource)
          allow(k8s_instantiated_resource).to receive(:validate_pod)
                                                .and_return(false)
        end

        it 'raises error if pod metadata fails validation' do
          validation_error_message = "PodValidationFailed"
          allow(k8s_object_lookup_class)
            .to receive(:find_object_by_name)
                  .with(k8s_resource_name, k8s_resource_value, k8s_host_namespace)
                  .and_raise(validation_error_message)

          expect { validator.(
            host_id: host_id,
              host_annotations: host_annotations,
              service_id: good_service_id,
              account: account,
              spiffe_id: spiffe_id
          ) }.to raise_error(RuntimeError,
                             validation_error_message)
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

          expected_message = /Container authenticator was not found in the pod/
          expect { validator.(
            host_id: host_id,
              host_annotations: host_annotations,
              service_id: good_service_id,
              account: account,
              spiffe_id: spiffe_id
          ) }
            .to raise_error(Errors::Authentication::AuthnK8s::ContainerNotFound, expected_message)
        end

        it 'raises ContainerNotFound if container cannot be found and container name annotation is missing' do
          allow(pod_spec).to receive(:initContainers)
                               .and_return({})
          allow(pod_spec).to receive(:containers)
                               .and_return({})
          allow(host_annotation_2).to receive(:values)
                                        .and_return({ :name => "notimportant" })

          expected_message = /Container authenticator was not found in the pod/
          expect { validator.(
            host_id: host_id,
              host_annotations: host_annotations,
              service_id: good_service_id,
              account: account,
              spiffe_id: spiffe_id
          ) }
            .to raise_error(Errors::Authentication::AuthnK8s::ContainerNotFound, expected_message)
        end

        it 'does not raise errors if all checks pass' do
          allow(pod_spec).to receive(:initContainers)
                               .and_return({})
          allow(pod_spec).to receive(:containers)
                               .and_return([double("Container1", :name => "notimportant"),
                                            double("Container2", :name => container_name)])
          allow(host_annotation_2).to receive(:values)
                                        .and_return({ :name => k8s_authn_container_name })
          allow(host_annotation_2).to receive(:[])
                                        .with(:value)
                                        .and_return(container_name)
          allow(resource_restrictions_class).to receive(:container_name)
                                             .and_return(container_name)

          begin
            validator.(
              host_id: host_id,
                host_annotations: host_annotations,
                service_id: good_service_id,
                account: account,
                spiffe_id: spiffe_id
            )
          rescue => err
            puts err
          end

          expect { validator.(
            host_id: host_id,
              host_annotations: host_annotations,
              service_id: good_service_id,
              account: account,
              spiffe_id: spiffe_id
          ) }.to_not raise_error
        end
      end
    end
  end
end
