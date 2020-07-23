# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::AuthnK8s::ExtractContainerName do
  include_context "running outside kubernetes"

  let(:service_id) { "service-id" }

  let(:container_name_annotation) { double("ContainerNameAnnotation") }
  let(:container_name_annotation_service_id_prefix) { double("ContainerNameAnnotation") }
  let(:container_name_annotation_kubernetes_prefix) { double("ContainerNameAnnotation") }

  let(:default_container_name) { "authenticator" }

  before(:each) do
    allow(container_name_annotation).to receive(:values)
                                          .and_return(container_name_annotation)
    allow(container_name_annotation).to receive(:[])
                                          .with(:name)
                                          .and_return("authn-k8s/authentication-container-name")
    allow(container_name_annotation).to receive(:[])
                                          .with(:value)
                                          .and_return("ContainerName")

    allow(container_name_annotation_service_id_prefix).to receive(:values)
                                                            .and_return(container_name_annotation_service_id_prefix)
    allow(container_name_annotation_service_id_prefix).to receive(:[])
                                                            .with(:name)
                                                            .and_return("authn-k8s/#{service_id}/authentication-container-name")
    allow(container_name_annotation_service_id_prefix).to receive(:[])
                                                            .with(:value)
                                                            .and_return("ServiceIdContainerName")

    allow(container_name_annotation_kubernetes_prefix).to receive(:values)
                                                            .and_return(container_name_annotation_kubernetes_prefix)
    allow(container_name_annotation_kubernetes_prefix).to receive(:[])
                                                            .with(:name)
                                                            .and_return("kubernetes/authentication-container-name")
    allow(container_name_annotation_kubernetes_prefix).to receive(:[])
                                                            .with(:value)
                                                            .and_return("KubernetesContainerName")
  end

  context "Host annotations for container name" do
    subject do
      Authentication::AuthnK8s::ExtractContainerName.new.call(
        host_annotations: host_annotations,
        service_id:       service_id
      )
    end

    context "all possible options exist" do
      let(:host_annotations) {
        [
          container_name_annotation,
          container_name_annotation_service_id_prefix,
          container_name_annotation_kubernetes_prefix
        ]
      }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end

      it "chooses the container name from the service-id annotation" do
        expect(subject).to eq("ServiceIdContainerName")
      end
    end

    context "only global and service-id exist" do
      let(:host_annotations) {
        [
          container_name_annotation,
          container_name_annotation_service_id_prefix
        ]
      }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end

      it "chooses the container name from the service-id annotation" do
        expect(subject).to eq("ServiceIdContainerName")
      end
    end

    context "only service-id & kubernetes exist" do
      let(:host_annotations) {
        [
          container_name_annotation_service_id_prefix,
          container_name_annotation_kubernetes_prefix
        ]
      }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end

      it "chooses the container name from the service-id annotation" do
        expect(subject).to eq("ServiceIdContainerName")
      end
    end

    context "only global & kubernetes exist" do
      let(:host_annotations) {
        [
          container_name_annotation,
          container_name_annotation_kubernetes_prefix
        ]
      }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end

      it "chooses the container name from the global annotation" do
        expect(subject).to eq("ContainerName")
      end
    end

    context "only service-id exists" do
      let(:host_annotations) {
        [
          container_name_annotation_service_id_prefix
        ]
      }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end

      it "chooses the container name from the service-id annotation" do
        expect(subject).to eq("ServiceIdContainerName")
      end
    end

    context "only global exists" do
      let(:host_annotations) {
        [
          container_name_annotation
        ]
      }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end

      it "chooses the container name from the global annotation" do
        expect(subject).to eq("ContainerName")
      end
    end

    context "only kubernetes exists" do
      let(:host_annotations) {
        [
          container_name_annotation_kubernetes_prefix
        ]
      }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end

      it "chooses the container name from the kubernetes annotation" do
        expect(subject).to eq("KubernetesContainerName")
      end
    end

    context "no annotation exists for container name" do
      let(:host_annotations) { [] }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end

      it "chooses the default container name" do
        expect(subject).to eq(default_container_name)
      end
    end
  end
end
