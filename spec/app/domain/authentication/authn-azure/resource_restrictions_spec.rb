# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::AuthnAzure::ResourceRestrictions do
  include_context "azure setup"

  let(:user_assigned_identity_service_id_scoped_annotation) { double("UserAssignedIdentityAnnotation") }
  let(:system_assigned_identity_service_id_scoped_annotation) { double("UserAssignedIdentityServiceIdScopeAnnotation") }

  before(:each) do
    define_host_annotation(
      host_annotation_type:  user_assigned_identity_service_id_scoped_annotation,
      host_annotation_key:   "#{granular_annotation_type}/user-assigned-identity",
      host_annotation_value: "some-user-assigned-service-id-scoped-value"
    )
    define_host_annotation(
      host_annotation_type:  system_assigned_identity_service_id_scoped_annotation,
      host_annotation_key:   "#{granular_annotation_type}/system-assigned-identity",
      host_annotation_value: "some-system-assigned-service-id-scoped-value"
    )
    define_host_annotation(
      host_annotation_type:  non_azure_annotation,
      host_annotation_key:   "#{global_annotation_type}/non-azure-annotation",
      host_annotation_value: "some-non-azure-value"
    )
  end

  context "resource restrictions in annotations" do
    subject do
      Authentication::AuthnAzure::ResourceRestrictions.new(
        role_annotations: role_annotations,
        service_id:       test_service_id,
        logger:           Rails.logger
      )
    end
    context("with a global scoped constraint") do
      let(:role_annotations) { [subscription_id_annotation, resource_group_annotation, user_assigned_identity_annotation, system_assigned_identity_annotation] }

      it "has a constraints hash with its value" do
        expect(subject.constraints).to eq(
          {
            subscription_id:          "some-subscription-id-value",
            resource_group:           "some-resource-group-value",
            user_assigned_identity:   "some-user-assigned-identity-value",
            system_assigned_identity: "some-system-assigned-identity-value"
          }
        )
      end
    end

    context("with a service-id scoped constraint") do
      let(:role_annotations) { [subscription_id_service_id_scoped_annotation, resource_group_service_id_scoped_annotation, user_assigned_identity_service_id_scoped_annotation, system_assigned_identity_service_id_scoped_annotation] }

      it "has a constraints hash with its value" do
        expect(subject.constraints).to eq(
          {
            subscription_id:          "some-subscription-id-service-id-scoped-value",
            resource_group:           "some-resource-group-service-id-scoped-value",
            user_assigned_identity:   "some-user-assigned-service-id-scoped-value",
            system_assigned_identity: "some-system-assigned-service-id-scoped-value"
          }
        )
      end
    end

    # Here we are only testing the scope of the subscription-id resource restriction because
    # we want to test that we grab the more granular resource restriction and the behaviour
    # is the same regardless of the annotation name
    context("with both global & service-id scoped constraints") do
      let(:role_annotations) { [subscription_id_annotation, subscription_id_service_id_scoped_annotation] }

      it ("chooses the service-id scoped constraint") do
        expect(subject.constraints).to eq({ subscription_id: "some-subscription-id-service-id-scoped-value" })
      end
    end

    context("without annotations") do
      let(:role_annotations) { [] }

      it "has an empty constraints hash" do
        expect(subject.constraints).to eq({})
      end
    end

    context("with annotations that are not Azure-specific") do
      let(:role_annotations) { [non_azure_annotation] }

      it "has an empty constraints hash" do
        expect(subject.constraints).to eq({})
      end
    end
  end
end
