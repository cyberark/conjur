# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::AuthnAzure::ValidateResourceRestrictions' do
  include_context "azure setup"
  include_context "security mocks"

  let(:account) { "account" }

  let(:hostname) { "azureTestVM" }
  let(:username) { "host/#{hostname}" }

  let(:resource_class) { double("Resource") }
  let(:host) { double("some-host") }

  let(:non_existent_host_id) { double ("some-non-existent-host-id") }
  let(:xms_mirid_token_field_user_assigned_identity) { "/subscriptions/some-subscription-id-value/resourcegroups/some-resource-group-value/providers/Microsoft.ManagedIdentity/userAssignedIdentities/some-user-assigned-identity-value" }
  let(:xms_mirid_token_field_system_assigned_identity) { "/subscriptions/some-subscription-id-value/resourcegroups/some-resource-group-value/providers/Microsoft.Compute/virtualMachines/some-system-assigned-identity-value" }

  let(:oid_token_field) { "test-oid" }

  let(:mismatched_subscription_id_annotation) { double("MismatchedSubscriptionIdAnnotation") }
  let(:mismatched_resource_group_annotation) { double("MismatchedResourceGroupAnnotation") }
  let(:mismatched_system_assigned_identity_annotation) { double("MismatchedSystemAssignedAnnotation") }
  let(:mismatched_user_assigned_identity_annotation) { double("MismatchedUserAssignedAnnotation") }

  let(:validate_azure_annotations) { double("ValidateAzureAnnotations") }

  before(:each) do
    allow(host).to receive(:annotations)
                     .and_return([subscription_id_annotation, resource_group_annotation])

    allow(validate_azure_annotations).to receive(:call)
                                           .and_return(true)

    allow(resource_class).to receive(:[])
                               .with("#{account}:host:#{hostname}")
                               .and_return(host)

    define_host_annotation(
      host_annotation_type:  system_assigned_identity_annotation,
      host_annotation_key:   "#{global_annotation_type}/system-assigned-identity",
      host_annotation_value: oid_token_field
    )
    define_host_annotation(
      host_annotation_type:  mismatched_subscription_id_annotation,
      host_annotation_key:   "#{global_annotation_type}/subscription-id",
      host_annotation_value: "mismatched-subscription-id"
    )
    define_host_annotation(
      host_annotation_type:  mismatched_resource_group_annotation,
      host_annotation_key:   "#{global_annotation_type}/resource-group",
      host_annotation_value: "mismatched-resource-group"
    )
    define_host_annotation(
      host_annotation_type:  mismatched_user_assigned_identity_annotation,
      host_annotation_key:   "#{global_annotation_type}/user-assigned-identity",
      host_annotation_value: "mismatched-user-assigned-identity"
    )
    define_host_annotation(
      host_annotation_type:  mismatched_system_assigned_identity_annotation,
      host_annotation_key:   "#{global_annotation_type}/system-assigned-identity",
      host_annotation_value: "mismatched-system-assigned-identity"
    )
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "Valid resource restrictions" do
    context "and an Azure token with matching data" do
      context "with no assigned Azure identity in resource restrictions" do
        subject do
          Authentication::AuthnAzure::ValidateResourceRestrictions.new(
            resource_class:             resource_class,
            validate_azure_annotations: validate_azure_annotations,
          ).call(
            account:               account,
            service_id:            test_service_id,
            username:              username,
            xms_mirid_token_field: xms_mirid_token_field_system_assigned_identity,
            oid_token_field:       oid_token_field
          )
        end

        it "does not raise an error" do
          expect { subject }.to_not raise_error
        end
      end

      context "with a user assigned Azure identity in resource restrictions" do
        before(:each) do
          allow(host).to receive(:annotations)
                           .and_return(
                             [
                               subscription_id_annotation,
                               resource_group_annotation,
                               user_assigned_identity_annotation
                             ]
                           )
        end
        subject do
          Authentication::AuthnAzure::ValidateResourceRestrictions.new(
            resource_class:             resource_class,
            validate_azure_annotations: validate_azure_annotations,
          ).call(
            account:               account,
            service_id:            test_service_id,
            username:              username,
            xms_mirid_token_field: xms_mirid_token_field_user_assigned_identity,
            oid_token_field:       oid_token_field
          )
        end

        it "does not raise an error" do
          expect { subject }.to_not raise_error
        end
      end

      context "with a system assigned Azure identity in resource restrictions" do
        subject do
          Authentication::AuthnAzure::ValidateResourceRestrictions.new(
            resource_class:             resource_class,
            validate_azure_annotations: validate_azure_annotations,
          ).call(
            account:               account,
            service_id:            test_service_id,
            username:              username,
            xms_mirid_token_field: xms_mirid_token_field_system_assigned_identity,
            oid_token_field:       oid_token_field
          )
        end

        it "does not raise an error" do
          expect { subject }.to_not raise_error
        end
      end
    end

    context "and an Azure token with non-matching data" do
      context "where the subscription id does not match the resource restrictions" do
        before(:each) do
          allow(host).to receive(:annotations)
                           .and_return(
                             [
                               mismatched_subscription_id_annotation,
                               resource_group_annotation
                             ]
                           )
        end
        subject do
          Authentication::AuthnAzure::ValidateResourceRestrictions.new(
            resource_class:             resource_class,
            validate_azure_annotations: validate_azure_annotations,
          ).call(
            account:               account,
            service_id:            test_service_id,
            username:              username,
            xms_mirid_token_field: xms_mirid_token_field_system_assigned_identity,
            oid_token_field:       oid_token_field
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(
            ::Errors::Authentication::AuthnAzure::InvalidResourceRestrictions
          )
        end
      end

      context "where the resource group does not match the resource restrictions" do
        before(:each) do
          allow(host).to receive(:annotations)
                           .and_return(
                             [
                               subscription_id_annotation,
                               mismatched_resource_group_annotation
                             ]
                           )
        end
        subject do
          Authentication::AuthnAzure::ValidateResourceRestrictions.new(
            resource_class:             resource_class,
            validate_azure_annotations: validate_azure_annotations,
          ).call(
            account:               account,
            service_id:            test_service_id,
            username:              username,
            xms_mirid_token_field: xms_mirid_token_field_system_assigned_identity,
            oid_token_field:       oid_token_field
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(
            ::Errors::Authentication::AuthnAzure::InvalidResourceRestrictions
          )
        end
      end

      context "where the user assigned identity does not match the resource restrictions" do
        before(:each) do
          allow(host).to receive(:annotations)
                           .and_return(
                             [
                               subscription_id_annotation,
                               resource_group_annotation,
                               mismatched_user_assigned_identity_annotation
                             ]
                           )
        end
        subject do
          Authentication::AuthnAzure::ValidateResourceRestrictions.new(
            resource_class:             resource_class,
            validate_azure_annotations: validate_azure_annotations,
          ).call(
            account:               account,
            service_id:            test_service_id,
            username:              username,
            xms_mirid_token_field: xms_mirid_token_field_system_assigned_identity,
            oid_token_field:       oid_token_field
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(
            ::Errors::Authentication::AuthnAzure::InvalidResourceRestrictions
          )
        end
      end

      context "where the system assigned identity does not match the resource restrictions" do
        before(:each) do
          allow(host).to receive(:annotations)
                           .and_return(
                             [subscription_id_annotation,
                               resource_group_annotation,
                               mismatched_system_assigned_identity_annotation
                             ]
                           )
        end
        subject do
          Authentication::AuthnAzure::ValidateResourceRestrictions.new(
            resource_class:             resource_class,
            validate_azure_annotations: validate_azure_annotations,
          ).call(
            account:               account,
            service_id:            test_service_id,
            username:              username,
            xms_mirid_token_field: xms_mirid_token_field_system_assigned_identity,
            oid_token_field:       oid_token_field
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(
            ::Errors::Authentication::AuthnAzure::InvalidResourceRestrictions
          )
        end
      end
    end
  end

  context "Invalid resource restrictions" do
    context "that does not have required constraints present in annotations" do
      before(:each) do
        allow(host).to receive(:annotations)
                         .and_return([])
      end
      subject do
        Authentication::AuthnAzure::ValidateResourceRestrictions.new(
          resource_class:             resource_class,
          validate_azure_annotations: validate_azure_annotations,
        ).call(
          account:               account,
          service_id:            test_service_id,
          username:              username,
          xms_mirid_token_field: xms_mirid_token_field_system_assigned_identity,
          oid_token_field:       oid_token_field
        )
      end
      it "raises an error" do
        expect { subject }.to raise_error(
          ::Errors::Authentication::AuthnAzure::RoleMissingConstraint
        )
      end
    end

    context "that has invalid constraint combination in annotations" do
      before(:each) do
        allow(host).to receive(:annotations)
                         .and_return(
                           [
                             subscription_id_annotation,
                             resource_group_annotation,
                             user_assigned_identity_annotation,
                             system_assigned_identity_annotation
                           ]
                         )
      end
      subject do
        Authentication::AuthnAzure::ValidateResourceRestrictions.new(
          resource_class:             resource_class,
          validate_azure_annotations: validate_azure_annotations,
        ).call(
          account:               account,
          service_id:            test_service_id,
          username:              username,
          xms_mirid_token_field: xms_mirid_token_field_system_assigned_identity,
          oid_token_field:       oid_token_field
        )
      end

      it "raise an error" do
        expect { subject }.to raise_error(
          ::Errors::Authentication::IllegalConstraintCombinations
        )
      end
    end

    context "that has invalid Azure annotations" do
      before(:each) do
        allow(host).to receive(:annotations)
                         .and_return(
                           [
                             subscription_id_annotation,
                             resource_group_annotation,
                             system_assigned_identity_annotation
                           ]
                         )

        allow(validate_azure_annotations).to receive(:call)
                                               .and_raise(
                                                 'FAKE_VALIDATE_RESOURCE_RESTRICTIONS_ERROR'
                                               )
      end
      subject do
        Authentication::AuthnAzure::ValidateResourceRestrictions.new(
          resource_class:             resource_class,
          validate_azure_annotations: validate_azure_annotations,
        ).call(
          account:               account,
          service_id:            test_service_id,
          username:              username,
          xms_mirid_token_field: xms_mirid_token_field_system_assigned_identity,
          oid_token_field:       oid_token_field
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(
          /FAKE_VALIDATE_RESOURCE_RESTRICTIONS_ERROR/
        )
      end
    end
  end

  context "A non-existent Role in Conjur" do
    before(:each) do
      allow(resource_class).to receive(:[])
                                 .and_return(nil)
    end
    subject do
      Authentication::AuthnAzure::ValidateResourceRestrictions.new(
        resource_class:             resource_class,
        validate_azure_annotations: validate_azure_annotations,
      ).call(
        account:               account,
        service_id:            test_service_id,
        username:              username,
        xms_mirid_token_field: xms_mirid_token_field_system_assigned_identity,
        oid_token_field:       oid_token_field
      )
    end

    it "raises an error" do
      expect { subject }.to raise_error(
        Errors::Authentication::Security::RoleNotFound
      )
    end
  end
end
