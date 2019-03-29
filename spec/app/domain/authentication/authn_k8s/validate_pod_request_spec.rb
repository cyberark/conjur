# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::AuthnK8s::ValidatePodRequest do
  include_context "running outside kubernetes"

  let(:error_template) { "An error occured" }

  let(:k8s_resolver) { double("K8sResolver") }

  let(:account) { "SomeAccount" }

  let(:host_id) { "HostId" }
  let(:host_role) { double("HostRole", :id => host_id) }

  let(:k8s_authn_container_name) { 'kubernetes/authentication-container-name' }
  let(:host_annotation_1) { double("Annot1", :values => { :name => "first" }) }
  let(:host_annotation_2) { double("Annot2") }

  let(:host_annotations) { [ host_annotation_1, host_annotation_2 ] }

  let(:host) { double("Host", :role => host_role,
                              :annotations => host_annotations) }

  let(:k8s_host_object) { "K8sHostObject" }
  let(:k8s_host_namespace) { "K8sHostNamespace" }
  let(:k8s_host) { double("K8sHost", :account => account,
                                     :conjur_host_id => host_id,
                                     :namespace => k8s_host_namespace,
                                     :object => k8s_host_object) }

  let(:container_name) { "ContainerName" }

  let(:bad_service_name) { "BadMockService" }
  let(:good_service_name) { "MockService" }

  let(:good_webservice) { Authentication::Webservice.new(
    account: account,
    authenticator_name: 'authn-k8s',
    service_id: good_service_name
  )}

  let(:spiffe_name) { "SpiffeName" }
  let(:spiffe_namespace) { "SpiffeNamespace" }
  let(:spiffe_id) { double("SpiffeId", :name => spiffe_name,
                                       :namespace => spiffe_namespace) }
  let(:pod_request) { double("PodRequest", :k8s_host => k8s_host,
                                           :spiffe_id => spiffe_id) }

  let(:dependencies) { { resource_repo: double(),
                         k8s_resolver: k8s_resolver } }

  before(:each) do
    allow(Resource).to receive(:[])
      .with(host_id)
      .and_return(host)

    allow(Resource).to receive(:[])
      .with("#{account}:webservice:conjur/authn-k8s/#{good_service_name}")
      .and_return(good_webservice)
    allow(Resource).to receive(:[])
      .with("#{account}:webservice:conjur/authn-k8s/#{bad_service_name}")
      .and_return(nil)
  end

  context "invocation" do
    subject(:validator) { Authentication::AuthnK8s::ValidatePodRequest
      .new(dependencies: dependencies) }

    it 'raises WebserviceNotFound error when webservice is missing' do
      allow(pod_request).to receive(:service_id).and_return(bad_service_name)

      expected_message = "Webservice '#{bad_service_name}' wasn't found"
      expect { validator.(pod_request: pod_request) }
        .to raise_error(Authentication::AuthnK8s::WebserviceNotFound, expected_message)
    end

    it 'raises HostNotAuthorized when host is not allowed to authenticate to service' do
      allow(pod_request).to receive(:service_id).and_return(good_service_name)
      allow(host_role).to receive(:allowed_to?)
        .with("authenticate", good_webservice)
        .and_return(false)

      expected_message = "'#{host_id}' does not have 'authenticate' privilege on #{good_service_name}"

      expect { validator.(pod_request: pod_request) }
        .to raise_error(Authentication::AuthnK8s::HostNotAuthorized, expected_message)
    end

    it 'raises PodNotFound when pod is not known' do
      allow(pod_request).to receive(:service_id).and_return(good_service_name)
      allow(host_role).to receive(:allowed_to?)
        .with("authenticate", good_webservice)
        .and_return(true)
      allow_any_instance_of(Authentication::AuthnK8s::K8sObjectLookup).to receive(:pod_by_name)
        .with(spiffe_name, spiffe_namespace)
        .and_return(nil)

      expected_message = "No Pod found for podname '#{spiffe_name}' " \
        "in namespace '#{spiffe_namespace}'"

      expect { validator.(pod_request: pod_request) }
        .to raise_error(Authentication::AuthnK8s::PodNotFound, expected_message)
    end

    context 'when namespace scoped' do
      let (:pod_spec) { double("PodSpec") }
      let (:pod) { double("Pod", :spec => pod_spec) }

      before(:each) do
        allow(pod_request).to receive(:service_id).and_return(good_service_name)
        allow(host_role).to receive(:allowed_to?)
          .with("authenticate", good_webservice)
          .and_return(true)
        allow_any_instance_of(Authentication::AuthnK8s::K8sObjectLookup).to receive(:pod_by_name)
          .with(spiffe_name, spiffe_namespace)
          .and_return(pod)
        allow(k8s_host).to receive(:namespace_scoped?)
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

        expected_message = "Container authenticator was not found for requesting pod"
        expect { validator.(pod_request: pod_request) }
          .to raise_error(Authentication::AuthnK8s::ContainerNotFound, expected_message)
      end

      it 'raises ContainerNotFound if container cannot be found and container name annotation is missing' do
        allow(pod_spec).to receive(:initContainers)
          .and_return({})
        allow(pod_spec).to receive(:containers)
          .and_return({})
        allow(host_annotation_2).to receive(:values)
          .and_return({ :name => "notimportant" })

        expected_message = "Container authenticator was not found for requesting pod"
        expect { validator.(pod_request: pod_request) }
          .to raise_error(Authentication::AuthnK8s::ContainerNotFound, expected_message)
      end

      it 'does not raise errors if all checks pass' do
        allow(pod_spec).to receive(:initContainers)
          .and_return({})
        allow(pod_spec).to receive(:containers)
          .and_return([ double("Container1", :name => "notimportant"),
                        double("Container2", :name => container_name) ])
        allow(host_annotation_2).to receive(:values)
          .and_return({ :name => k8s_authn_container_name })
        allow(host_annotation_2).to receive(:[])
          .with(:value)
          .and_return(container_name)

        expect { validator.(pod_request: pod_request) }.to_not raise_error
      end
    end

    context 'when not namespace scoped' do
      let (:pod_spec) { double("PodSpec") }
      let (:pod) { double("Pod", :spec => pod_spec) }
      let (:k8s_host_controller) { "K8sHostController" }

      before(:each) do
        allow(pod_request).to receive(:service_id).and_return(good_service_name)
        allow(host_role).to receive(:allowed_to?)
          .with("authenticate", good_webservice)
          .and_return(true)
        allow_any_instance_of(Authentication::AuthnK8s::K8sObjectLookup).to receive(:pod_by_name)
          .with(spiffe_name, spiffe_namespace)
          .and_return(pod)
        allow(k8s_host).to receive(:namespace_scoped?)
          .and_return(false)
        allow(k8s_host).to receive(:controller)
          .and_return(k8s_host_controller)
      end

      it 'raises ScopeNotSupported if host is not in permitted scope' do
        allow(k8s_host).to receive(:permitted_scope?)
          .and_return(false)

        expected_message = "Resource type '#{k8s_host_controller}' identity scope is " \
          "not supported in this version of authn-k8s"
        expect { validator.(pod_request: pod_request) }
          .to raise_error(Authentication::AuthnK8s::ScopeNotSupported, expected_message)
      end

      context 'in permitted scope' do
        let (:k8s_resolver_for_controller) { double("K8sResoverForController") }
        let (:k8s_host_controller_object) { double("K8sHostControllerObject") }
        let (:k8s_host_instantiated_controller) { double("K8sHostInstantiatedController") }

        before(:each) do
          allow(k8s_host).to receive(:permitted_scope?)
            .and_return(true)
          allow_any_instance_of(Authentication::AuthnK8s::K8sObjectLookup).to receive(:find_object_by_name)
            .with(k8s_host_controller, k8s_host_object, k8s_host_namespace)
            .and_return(k8s_host_controller_object)
          allow(Authentication::AuthnK8s::K8sResolver).to receive(:for_controller)
            .with(k8s_host_controller)
            .and_return(k8s_resolver_for_controller)
          allow(k8s_resolver_for_controller).to receive(:new)
            .with(k8s_host_controller_object, pod, Authentication::AuthnK8s::K8sObjectLookup)
            .and_return(k8s_host_instantiated_controller)
          allow(k8s_host_instantiated_controller).to receive(:validate_pod)
            .and_return(false)
        end

        it 'raises ControllerNotFound if controller object cannot be found' do
          allow_any_instance_of(Authentication::AuthnK8s::K8sObjectLookup)
            .to receive(:find_object_by_name)
            .with(k8s_host_controller, k8s_host_object, k8s_host_namespace)
            .and_return(nil)

          expected_message = "Kubernetes K8sHostController K8sHostObject " \
            "not found in namespace K8sHostNamespace"
          expect { validator.(pod_request: pod_request) }
            .to raise_error(Authentication::AuthnK8s::ControllerNotFound, expected_message)
        end

        it 'raises error if pod metadata fails validation' do
          expected_message = "PodValidationFailed"

          allow_any_instance_of(Authentication::AuthnK8s::K8sObjectLookup)
            .to receive(:find_object_by_name)
            .with(k8s_host_controller, k8s_host_object, k8s_host_namespace)
            .and_raise(expected_message)

          expect { validator.(pod_request: pod_request) }.to raise_error(RuntimeError,
                                                                         expected_message)
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

          expected_message = "Container authenticator was not found for requesting pod"
          expect { validator.(pod_request: pod_request) }
            .to raise_error(Authentication::AuthnK8s::ContainerNotFound, expected_message)
        end

        it 'raises ContainerNotFound if container cannot be found and container name annotation is missing' do
          allow(pod_spec).to receive(:initContainers)
            .and_return({})
          allow(pod_spec).to receive(:containers)
            .and_return({})
          allow(host_annotation_2).to receive(:values)
            .and_return({ :name => "notimportant" })

          expected_message = "Container authenticator was not found for requesting pod"
          expect { validator.(pod_request: pod_request) }
            .to raise_error(Authentication::AuthnK8s::ContainerNotFound, expected_message)
        end

        it 'does not raise errors if all checks pass' do
          allow(pod_spec).to receive(:initContainers)
            .and_return({})
          allow(pod_spec).to receive(:containers)
            .and_return([ double("Container1", :name => "notimportant"),
                          double("Container2", :name => container_name) ])
          allow(host_annotation_2).to receive(:values)
            .and_return({ :name => k8s_authn_container_name })
          allow(host_annotation_2).to receive(:[])
            .with(:value)
            .and_return(container_name)

          begin
            validator.(pod_request: pod_request)
          rescue => err
            puts err
          end

          expect { validator.(pod_request: pod_request) }.to_not raise_error
        end
      end
    end
  end
end
