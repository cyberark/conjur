# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::AuthnAzure::ApplicationIdentity do
  include_context "azure setup"

  let(:subscription_id_annotation) { double("SubscriptionIdAnnotation") }
  let(:subscription_id_service_id_scoped_annotation) { double("SubscriptionIdServiceIdAnnotation") }

  let(:resource_group_annotation) { double("ResourceGroupAnnotation") }
  let(:resource_group_service_id_scoped_annotation) { double("ResourceGroupAnnotation") }

  let(:user_assigned_identity_annotation) { double("UserAssignedIdentityAnnotation") }
  let(:user_assigned_identity_service_id_scoped_annotation) { double("UserAssignedIdentityAnnotation") }

  let(:non_azure_annotation) { double("NonAzureAnnotation") }

  let(:test_service_id) { "MockService" }

  let(:granular_annotation_type) { "authn-azure/#{test_service_id}" }

  before(:each) do
    define_host_annotation(subscription_id_service_id_scoped_annotation, "#{granular_annotation_type}/subscription-id", "some-subscription-id-service-id-scoped-value")
    define_host_annotation(resource_group_service_id_scoped_annotation, "#{granular_annotation_type}/resource-group", "some-resource-group-service-id-scoped-value")
    define_host_annotation(user_assigned_identity_service_id_scoped_annotation, "#{granular_annotation_type}/user-assigned-identity", "some-user-assigned-service-id-scoped-value")
    define_host_annotation(non_azure_annotation, "#{global_annotation_type}/non-azure-annotation", "some-non-azure-value")
  end

  context "An application identity in annotations" do
    subject(:application_identity) {
      Authentication::AuthnAzure::ApplicationIdentity.new(
        role_annotations: role_annotations,
        service_id:       test_service_id
      )
    }
    context("with a global scoped constraint") do
      let(:role_annotations) { [subscription_id_annotation, resource_group_annotation, user_assigned_identity_annotation] }

      it "Returns Hash of the constraint and its value" do
        expect(subject.constraints).to eq({ subscription_id: "some-subscription-id-value", resource_group: "some-resource-group-value", user_assigned_identity: "some-user-assigned-identity-value" })
      end
    end

    context("with a service-id scoped constraint") do
      let(:role_annotations) { [subscription_id_service_id_scoped_annotation, resource_group_service_id_scoped_annotation, user_assigned_identity_service_id_scoped_annotation] }

      it "Returns Hash of the constraint and its value" do
        expect(subject.constraints).to eq({ subscription_id: "some-subscription-id-service-id-scoped-value", resource_group: "some-resource-group-service-id-scoped-value", user_assigned_identity: "some-user-assigned-service-id-scoped-value" })
      end
    end

    context("with both global & service-id scoped constraints") do
      let(:role_annotations) { [subscription_id_annotation, subscription_id_service_id_scoped_annotation] }

      it ("chooses the service-id scoped constraint") do
        expect(subject.constraints).to eq({ subscription_id: "some-subscription-id-service-id-scoped-value" })
      end
    end

    context("with an empty annotation") do
      let(:role_annotations) { [] }

      it "Returns Hash of the constraint and an empty value" do
        expect(subject.constraints).to eq({ })
      end
    end

    context("with annotations that are not Azure-specific") do
      let(:role_annotations) { [non_azure_annotation] }

      it "Returns empty Hash" do
        expect(subject.constraints).to eq({ })
      end
    end
  end
end
