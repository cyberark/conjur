# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::AuthnK8s::ResourceRestrictions do
  include_context "running outside kubernetes"

  let(:host_id_prefix) { "accountName:host:" }

  let(:namespace) { "K8sNamespace" }

  let(:k8s_resource_name) { "K8sResourceName" }
  let(:k8s_resource_value) { "K8sResourceValue" }

  let(:namespace_annotation) { double("NamespaceAnnotation") }
  let(:namespace_annotation_service_id_scoped) { double("NamespaceServiceIdAnnotation") }

  let(:service_account_annotation) { double("ServiceAccountAnnotation") }
  let(:pod_annotation) { double("PodAnnotation") }
  let(:deployment_annotation) { double("DeploymentAnnotation") }
  let(:stateful_set_annotation) { double("StatefulSetAnnotation") }
  let(:deployment_config_annotation) { double("DeploymentConfigAnnotation") }

  let(:container_name_annotation) { double("ContainerNameAnnotation") }

  let(:invalid_annotation) { double("InvalidAnnotation") }

  let(:good_service_id) { "MockService" }

  before(:each) do
    allow(namespace_annotation).to receive(:values)
                                     .and_return(namespace_annotation)
    allow(namespace_annotation).to receive(:[])
                                     .with(:name)
                                     .and_return("authn-k8s/namespace")
    allow(namespace_annotation).to receive(:[])
                                     .with(:value)
                                     .and_return("K8sNamespace")

    allow(namespace_annotation_service_id_scoped).to receive(:values)
                                                       .and_return(namespace_annotation_service_id_scoped)
    allow(namespace_annotation_service_id_scoped).to receive(:[])
                                                       .with(:name)
                                                       .and_return("authn-k8s/#{good_service_id}/namespace")
    allow(namespace_annotation_service_id_scoped).to receive(:[])
                                                       .with(:value)
                                                       .and_return("K8sNamespaceServiceIdScoped")

    allow(service_account_annotation).to receive(:values)
                                           .and_return(service_account_annotation)
    allow(service_account_annotation).to receive(:[])
                                           .with(:name)
                                           .and_return("authn-k8s/service-account")
    allow(service_account_annotation).to receive(:[])
                                           .with(:value)
                                           .and_return("K8sServiceAccount")

    allow(pod_annotation).to receive(:values)
                               .and_return(pod_annotation)
    allow(pod_annotation).to receive(:[])
                               .with(:name)
                               .and_return("authn-k8s/pod")
    allow(pod_annotation).to receive(:[])
                               .with(:value)
                               .and_return("K8sPod")

    allow(deployment_annotation).to receive(:values)
                                      .and_return(deployment_annotation)
    allow(deployment_annotation).to receive(:[])
                                      .with(:name)
                                      .and_return("authn-k8s/deployment")
    allow(deployment_annotation).to receive(:[])
                                      .with(:value)
                                      .and_return("K8sDeployment")

    allow(stateful_set_annotation).to receive(:values)
                                        .and_return(stateful_set_annotation)
    allow(stateful_set_annotation).to receive(:[])
                                        .with(:name)
                                        .and_return("authn-k8s/stateful-set")
    allow(stateful_set_annotation).to receive(:[])
                                        .with(:value)
                                        .and_return("K8sStatefulSet")

    allow(deployment_config_annotation).to receive(:values)
                                             .and_return(deployment_config_annotation)
    allow(deployment_config_annotation).to receive(:[])
                                             .with(:name)
                                             .and_return("authn-k8s/deployment-config")
    allow(deployment_config_annotation).to receive(:[])
                                             .with(:value)
                                             .and_return("K8sDeploymentConfig")

    allow(container_name_annotation).to receive(:values)
                                          .and_return(container_name_annotation)
    allow(container_name_annotation).to receive(:[])
                                          .with(:name)
                                          .and_return("authn-k8s/authentication-container-name")
    allow(container_name_annotation).to receive(:[])
                                          .with(:value)
                                          .and_return("ContainerName")

    allow(invalid_annotation).to receive(:values)
                                   .and_return(invalid_annotation)
    allow(invalid_annotation).to receive(:[])
                                   .with(:name)
                                   .and_return("authn-k8s/non_existing")
  end

  context "initialization" do
    subject do
      Authentication::AuthnK8s::ResourceRestrictions.new(
        host_id:          host_id,
        host_annotations: host_annotations,
        service_id:       good_service_id,
        logger:           Rails.logger
      )
    end

    context "Resource restrictions in host id" do
      let(:host_annotations) { [] }
      let(:host_id) { [ namespace, k8s_resource_name, k8s_resource_value] }

      context "when is namespace scoped" do
        let(:k8s_resource_name) { "*" }
        let(:k8s_resource_value) { "*" }

        it "does not raise an error" do
          expect { subject }.not_to raise_error
        end

        it "has resources with its value" do
          expect(subject.resources).to eq(
            [
              Authentication::AuthnK8s::K8sResource.new(
                type: "namespace",
                value: namespace
              )
            ]
          )
        end

        it "has a valid configuration" do
          expect { subject }.to_not raise_error
        end

        context "when using authenticator container name annotation" do
          let(:host_annotations) { [container_name_annotation] }

          it "does not raise an error" do
            expect { subject }.not_to raise_error
          end
        end
      end

      context "when is not namespace scoped" do
        let(:k8s_resource_name) { "service_account" }
        let(:k8s_resource_value) { "some_service_account" }

        it "does not raise an error" do
          expect { subject }.not_to raise_error
        end

        it "has resources with its value" do
          expect(subject.resources).to eq(
            [
              Authentication::AuthnK8s::K8sResource.new(
                type: "namespace",
                value: namespace
              ),
              Authentication::AuthnK8s::K8sResource.new(
                type: "service-account",
                value: k8s_resource_value
              )
            ]
          )
        end

        it "has a valid configuration" do
          expect { subject }.to_not raise_error
        end
      end

      context "with invalid configuration" do
        context "where the id isn't a 3 part string" do
          let(:host_id) { "#{host_id_prefix}HostId" }

          it "raises an error" do
            expect { subject }.to raise_error(::Errors::Authentication::AuthnK8s::InvalidHostId)
          end
        end

        context "with a non existing resource" do
          let(:k8s_resource_name) { "non_existing_resource" }

          it "raises an error" do
            expect { subject }.to raise_error(::Errors::Authentication::Constraints::ConstraintNotSupported)
          end
        end
      end
    end

    context "Resource restrictions in annotations" do
      let(:host_id) { "#{host_id_prefix}HostId" }

      context "when is namespace scoped" do
        context "in a global constraint" do
          let(:host_annotations) { [namespace_annotation] }

          it "does not raise an error" do
            expect { subject }.not_to raise_error
          end

          it "has resources with its value" do
            expect(subject.resources).to eq(
              [
                Authentication::AuthnK8s::K8sResource.new(
                  type: "namespace",
                  value: "K8sNamespace"
                )
              ]
            )
          end

          it "has a valid configuration" do
          expect { subject }.to_not raise_error
        end
        end

        context "in service-id constraint" do
          let(:host_annotations) { [namespace_annotation_service_id_scoped] }

          it "does not raise an error" do
            expect { subject }.not_to raise_error
          end

          it "has resources with its value" do
            expect(subject.resources).to eq(
              [
                Authentication::AuthnK8s::K8sResource.new(
                  type: "namespace",
                  value: "K8sNamespaceServiceIdScoped"
                )
              ]
            )
          end

          it "has a valid configuration" do
          expect { subject }.to_not raise_error
        end
        end

        context "in both global & service-id constraints" do
          let(:host_annotations) { [namespace_annotation, namespace_annotation_service_id_scoped] }

          it "does not raise an error" do
            expect { subject }.not_to raise_error
          end

          it "chooses the service-id constraint" do
            expect(subject.resources).to eq(
              [
                Authentication::AuthnK8s::K8sResource.new(
                  type: "namespace",
                  value: "K8sNamespaceServiceIdScoped"
                )
              ]
            )
          end

          it "does not choose the service-id constraint if it is from another service-id" do
            allow(namespace_annotation_service_id_scoped).to receive(:[])
                                                               .with(:name)
                                                               .and_return("authn-k8s/another-service-id/namespace")
            expect(subject.resources).to eq(
              [
                Authentication::AuthnK8s::K8sResource.new(
                  type: "namespace",
                  value: "K8sNamespace"
                )
              ]
            )
          end
        end
      end

      context "when is not namespace scoped" do
        context "has only a service account constraint" do
          let(:host_annotations) { [namespace_annotation, service_account_annotation] }

          it "does not raise an error" do
            expect { subject }.not_to raise_error
          end

          it "has resources with its value" do
            expect(subject.resources).to eq(
              [
                Authentication::AuthnK8s::K8sResource.new(
                  type: "namespace",
                  value: "K8sNamespace"
                ),
                Authentication::AuthnK8s::K8sResource.new(
                  type: "service-account",
                  value: "K8sServiceAccount"
                )
              ]
            )
          end

          it "has a valid configuration" do
          expect { subject }.to_not raise_error
        end
        end

        context "has only a pod constraint" do
          let(:host_annotations) { [namespace_annotation, pod_annotation] }

          it "does not raise an error" do
            expect { subject }.not_to raise_error
          end

          it "has resources with its value" do
            expect(subject.resources).to eq(
              [
                Authentication::AuthnK8s::K8sResource.new(
                  type: "namespace",
                  value: "K8sNamespace"
                ),
                Authentication::AuthnK8s::K8sResource.new(
                  type: "pod",
                  value: "K8sPod"
                )
              ]
            )
          end

          it "has a valid configuration" do
          expect { subject }.to_not raise_error
        end
        end

        context "has only a deployment constraint" do
          let(:host_annotations) { [namespace_annotation, deployment_annotation] }

          it "does not raise an error" do
            expect { subject }.not_to raise_error
          end

          it "has resources with its value" do
            expect(subject.resources).to eq(
              [
                Authentication::AuthnK8s::K8sResource.new(
                  type: "namespace",
                  value: "K8sNamespace"
                ),
                Authentication::AuthnK8s::K8sResource.new(
                  type: "deployment",
                  value: "K8sDeployment"
                )
              ]
            )
          end

          it "has a valid configuration" do
          expect { subject }.to_not raise_error
        end
        end

        context "has only a stateful set constraint" do
          let(:host_annotations) { [namespace_annotation, stateful_set_annotation] }

          it "does not raise an error" do
            expect { subject }.not_to raise_error
          end

          it "has resources with its value" do
            expect(subject.resources).to eq(
              [
                Authentication::AuthnK8s::K8sResource.new(
                  type: "namespace",
                  value: "K8sNamespace"
                ),
                Authentication::AuthnK8s::K8sResource.new(
                  type: "stateful-set",
                  value: "K8sStatefulSet"
                )
              ]
            )
          end

          it "has a valid configuration" do
          expect { subject }.to_not raise_error
        end
        end

        context "has only a deployment config constraint" do
          let(:host_annotations) { [namespace_annotation, deployment_config_annotation] }

          it "does not raise an error" do
            expect { subject }.not_to raise_error
          end

          it "has resources with its value" do
            expect(subject.resources).to eq(
              [
                Authentication::AuthnK8s::K8sResource.new(
                  type: "namespace",
                  value: "K8sNamespace"
                ),
                Authentication::AuthnK8s::K8sResource.new(
                  type: "deployment-config",
                  value: "K8sDeploymentConfig"
                )
              ]
            )
          end

          it "has a valid configuration" do
          expect { subject }.to_not raise_error
        end
        end
      end

      context "with invalid configuration" do
        context "where namespace constraint doesn't exist" do
          let(:host_annotations) { [service_account_annotation] }

          it "raises an error" do
            expect { subject }.to raise_error(Errors::Authentication::Constraints::RoleMissingConstraints)
          end
        end

        context "with a non existing resource" do
          context "in a global constraint" do
            let(:host_annotations) { [namespace_annotation, invalid_annotation] }

            it "raises an error" do
              expect { subject }.to raise_error(::Errors::Authentication::Constraints::ConstraintNotSupported)
            end
          end

          context "in service-id constraint" do
            let(:host_annotations) { [namespace_annotation, invalid_annotation] }

            before(:each) do
              allow(invalid_annotation).to receive(:[])
                                             .with(:name)
                                             .and_return("authn-k8s/#{good_service_id}/non_existing")
            end

            it "raises an error" do
              expect { subject }.to raise_error(::Errors::Authentication::Constraints::ConstraintNotSupported)
            end
          end
        end

        context "with an invalid constraint combination" do
          context "deployment and deployment_config" do
            let(:host_annotations) { [namespace_annotation, deployment_annotation, deployment_config_annotation] }

            it "raises an error" do
              expect { subject }.to raise_error(::Errors::Authentication::Constraints::IllegalConstraintCombinations)
            end
          end

          context "deployment and stateful_set" do
            let(:host_annotations) { [namespace_annotation, deployment_annotation, stateful_set_annotation] }

            it "raises an error" do
              expect { subject }.to raise_error(::Errors::Authentication::Constraints::IllegalConstraintCombinations)
            end
          end

          context "deployment_config and stateful_set" do
            let(:host_annotations) { [namespace_annotation, deployment_config_annotation, stateful_set_annotation] }

            it "raises an error" do
              expect { subject }.to raise_error(::Errors::Authentication::Constraints::IllegalConstraintCombinations)
            end
          end

          context "deployment, deployment_config and stateful_set" do
            let(:host_annotations) { [namespace_annotation, deployment_annotation, deployment_config_annotation, stateful_set_annotation] }

            it "raises an error" do
              expect { subject }.to raise_error(::Errors::Authentication::Constraints::IllegalConstraintCombinations)
            end
          end
        end

        context "where a constraint is missing a slash after authn-k8s" do
          let(:host_annotations) { [service_account_annotation, namespace_annotation] }

          before(:each) do
            allow(namespace_annotation).to receive(:[])
                                             .with(:name)
                                             .and_return("authn-k8sSomething/namespace")
          end

          it "ignores the annotation" do
            # the namespace annotation is not present
            expect { subject }.to raise_error(Errors::Authentication::Constraints::RoleMissingConstraints)
          end
        end
      end
    end

    context "Resource restrictions in host id and in annotations" do
      let(:host_annotations) { [namespace_annotation, service_account_annotation] }
      let(:k8s_resource_name) { "service_account" }
      let(:host_id) { "#{host_id_prefix}#{namespace}/#{k8s_resource_name}/#{k8s_resource_value}" }

      before(:each) do
        allow(namespace_annotation).to receive(:[])
                                         .with(:value)
                                         .and_return("OtherK8sNamespace")

        allow(service_account_annotation).to receive(:[])
                                               .with(:value)
                                               .and_return("OtherK8sServiceAccount")
      end

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end

      it "takes the resource restrictions from the annotations" do
        expect(subject.resources).to eq(
          [
            Authentication::AuthnK8s::K8sResource.new(
              type: "namespace",
              value: "OtherK8sNamespace"
            ),
            Authentication::AuthnK8s::K8sResource.new(
              type: "service-account",
              value: "OtherK8sServiceAccount"
            )
          ]
        )
      end
    end
  end
end
