# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::AuthnAzure::ValidateApplicationIdentity' do
  let(:account) { "account" }
  let(:service_id) { "serviceId" }
  let(:hostname) { "azureTestVM" }
  let(:username) { "host/#{hostname}" }

  let(:resource_class) { double("Resource") }
  let(:host) { double ("some-host") }
  let(:non_existent_host_id) { double ("some-non-existent-host-id") }
  let(:xms_mirid_token_field_user_assigned_identity) { "/subscriptions/some-subscription-id-value/resourcegroups/some-resource-group-value/providers/Microsoft.ManagedIdentity/userAssignedIdentities/some-user-assigned-identity-value" }
  let(:xms_mirid_token_field_system_assigned_identity) { "/subscriptions/some-subscription-id-value/resourcegroups/some-resource-group-value/providers/Microsoft.Compute/virtualMachines/some-system-assigned-identity-value" }

  let(:xms_mirid_token_missing_subscription_id_field) { "/resourcegroups/some-resource-group-value/providers/Microsoft.ManagedIdentity/userAssignedIdentities/some-system-assigned-identity-value" }
  let(:xms_mirid_token_missing_resource_groups_field) { "/subscriptions/some-subscription-id-value/providers/Microsoft.ManagedIdentity/some-user-assigned-identity-value" }
  let(:xms_mirid_token_missing_providers_field) { "/subscriptions/some-subscription-id-value/resourcegroups/some-resource-group-value/" }
  let(:xms_mirid_token_missing_initial_slash) { "subscriptions/some-subscription-id-value/resourcegroups/some-resource-group-value/providers/Microsoft.ManagedIdentity/userAssignedIdentities/some-system-assigned-identity-value" }

  let(:invalid_xms_mirid_token_providers_field) { "/subscriptions/some-subscription-id-value/resourcegroups/some-resource-group-value/providers/Microsoft.ManagedIdentity/some-user-assigned-identity-value" }

  let(:oid_token_field) { "test-oid" }

  let(:subscription_id_annotation) { double("SubscriptionIdAnnotation") }
  let(:resource_group_annotation) { double("ResourceGroupAnnotation") }
  let(:user_assigned_identity_annotation) { double("UserAssignedIdentityAnnotation") }
  let(:system_assigned_identity_annotation) { double("SystemAssignedIdentityAnnotation") }

  let(:mismatched_subscription_id_annotation) { double("MismatchedSubscriptionIdAnnotation") }
  let(:mismatched_resource_group_annotation) { double("MismatchedResourceGroupAnnotation") }
  let(:mismatched_system_assigned_identity_annotation) { double("MismatchedSystemAssignedAnnotation") }
  let(:mismatched_user_assigned_identity_annotation) { double("MismatchedUserAssignedAnnotation") }

  let(:validate_azure_annotations) { double("ValidateAzureAnnotations") }

  def mock_annotation_builder(host_annotation_type, host_annotation_key, host_annotation_value)
    allow(host_annotation_type).to receive(:values)
                     .and_return(host_annotation_type)
    allow(host_annotation_type).to receive(:[])
                     .with(:name)
                     .and_return(host_annotation_key)
    allow(host_annotation_type).to receive(:[])
                     .with(:value)
                     .and_return(host_annotation_value)
  end

  before(:each) do
    allow(host).to receive(:annotations)
                     .and_return([subscription_id_annotation, resource_group_annotation])

    allow(validate_azure_annotations).to receive(:call)
                                           .and_return(true)

    allow(resource_class).to receive(:[])
                               .with("#{account}:host:#{hostname}")
                               .and_return(host)

    mock_annotation_builder(subscription_id_annotation,"authn-azure/subscription-id", "some-subscription-id-value")
    mock_annotation_builder(resource_group_annotation,"authn-azure/resource-group", "some-resource-group-value")
    mock_annotation_builder(user_assigned_identity_annotation,"authn-azure/user-assigned-identity", "some-user-assigned-identity-value")
    mock_annotation_builder(system_assigned_identity_annotation,"authn-azure/system-assigned-identity", oid_token_field)
    mock_annotation_builder(mismatched_subscription_id_annotation, "authn-azure/subscription-id", "mismatched-subscription-id")
    mock_annotation_builder(mismatched_resource_group_annotation, "authn-azure/resource-group", "mismatched-resource-group")
    mock_annotation_builder(mismatched_user_assigned_identity_annotation, "authn-azure/user-assigned-identity", "mismatched-user-assigned-identity")
    mock_annotation_builder(mismatched_system_assigned_identity_annotation, "authn-azure/system-assigned-identity", "mismatched-system-assigned-identity")
  end


  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "A valid xms_mirid claim in the Azure token" do
    context "with a valid application identity" do
      context "and a non-existent Role in Conjur" do
        before(:each) do
          allow(resource_class).to receive(:[])
                                     .and_return(nil)
        end
        subject do
          Authentication::AuthnAzure::ValidateApplicationIdentity.new(
            resource_class:             resource_class,
            validate_azure_annotations: validate_azure_annotations,
            ).call(
            account:               account,
            service_id:            service_id,
            username:              username,
            xms_mirid_token_field: xms_mirid_token_field_system_assigned_identity,
            oid_token_field:       oid_token_field
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(::Errors::Authentication::Security::RoleNotFound)
        end
      end
      context "and an Azure token with matching data" do
        context "with no assigned Azure identity in application identity" do
          subject do
            Authentication::AuthnAzure::ValidateApplicationIdentity.new(
              resource_class:             resource_class,
              validate_azure_annotations: validate_azure_annotations,
            ).call(
              account:               account,
              service_id:            service_id,
              username:              username,
              xms_mirid_token_field: xms_mirid_token_field_system_assigned_identity,
              oid_token_field:       oid_token_field
            )
          end

          it "does not raise an error" do
            expect { subject }.to_not raise_error
          end
        end

        context "with a user assigned Azure identity in application identity" do
          before(:each) do
            allow(host).to receive(:annotations)
                             .and_return([subscription_id_annotation, resource_group_annotation, user_assigned_identity_annotation])
          end
          subject do
            Authentication::AuthnAzure::ValidateApplicationIdentity.new(
              resource_class:             resource_class,
              validate_azure_annotations: validate_azure_annotations,
            ).call(
              account:               account,
              service_id:            service_id,
              username:              username,
              xms_mirid_token_field: xms_mirid_token_field_user_assigned_identity,
              oid_token_field:       oid_token_field
            )
          end

          it "does not raise an error" do
            expect { subject }.to_not raise_error
          end
        end

        context "with a system assigned Azure identity in application identity" do
          subject do
            Authentication::AuthnAzure::ValidateApplicationIdentity.new(
              resource_class:             resource_class,
              validate_azure_annotations: validate_azure_annotations,
            ).call(
              account:               account,
              service_id:            service_id,
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
        context "where the subscription id does not match the application identity" do
          before(:each) do
            allow(host).to receive(:annotations)
                             .and_return([mismatched_subscription_id_annotation, resource_group_annotation])
          end
          subject do
            Authentication::AuthnAzure::ValidateApplicationIdentity.new(
              resource_class:             resource_class,
              validate_azure_annotations: validate_azure_annotations,
            ).call(
              account:               account,
              service_id:            service_id,
              username:              username,
              xms_mirid_token_field: xms_mirid_token_field_system_assigned_identity,
              oid_token_field:       oid_token_field
            )
          end

          it "raises an error" do
            expect { subject }.to raise_error(::Errors::Authentication::AuthnAzure::InvalidApplicationIdentity)
          end
        end
        context "where the resource group does not match the application identity" do
          before(:each) do
            allow(host).to receive(:annotations)
                             .and_return([subscription_id_annotation, mismatched_resource_group_annotation])
          end
          subject do
            Authentication::AuthnAzure::ValidateApplicationIdentity.new(
              resource_class:             resource_class,
              validate_azure_annotations: validate_azure_annotations,
            ).call(
              account:               account,
              service_id:            service_id,
              username:              username,
              xms_mirid_token_field: xms_mirid_token_field_system_assigned_identity,
              oid_token_field:       oid_token_field
            )
          end

          it "raises an error" do
            expect { subject }.to raise_error(::Errors::Authentication::AuthnAzure::InvalidApplicationIdentity)
          end
        end

        context "where the user assigned identity does not match the application identity" do
          before(:each) do
            allow(host).to receive(:annotations)
                             .and_return([subscription_id_annotation, resource_group_annotation, mismatched_user_assigned_identity_annotation])
          end
          subject do
            Authentication::AuthnAzure::ValidateApplicationIdentity.new(
              resource_class:             resource_class,
              validate_azure_annotations: validate_azure_annotations,
            ).call(
              account:               account,
              service_id:            service_id,
              username:              username,
              xms_mirid_token_field: xms_mirid_token_field_system_assigned_identity,
              oid_token_field:       oid_token_field
            )
          end

          it "raises an error" do
            expect { subject }.to raise_error(::Errors::Authentication::AuthnAzure::InvalidApplicationIdentity)
          end
        end

        context "where the system assigned identity does not match the application identity" do
          before(:each) do
            allow(host).to receive(:annotations)
                             .and_return([subscription_id_annotation, resource_group_annotation, mismatched_system_assigned_identity_annotation])
          end
          subject do
            Authentication::AuthnAzure::ValidateApplicationIdentity.new(
              resource_class:             resource_class,
              validate_azure_annotations: validate_azure_annotations,
            ).call(
              account:               account,
              service_id:            service_id,
              username:              username,
              xms_mirid_token_field: xms_mirid_token_field_system_assigned_identity,
              oid_token_field:       oid_token_field
            )
          end

          it "raises an error" do
            expect { subject }.to raise_error(::Errors::Authentication::AuthnAzure::InvalidApplicationIdentity)
          end
        end

      end
    end

    context "an invalid application identity" do
      context "that does not have required constraints present in annotations" do
        before(:each) do
          allow(host).to receive(:annotations)
                           .and_return([])
        end
        subject do
          Authentication::AuthnAzure::ValidateApplicationIdentity.new(
            resource_class:             resource_class,
            validate_azure_annotations: validate_azure_annotations,
          ).call(
            account:               account,
            service_id:            service_id,
            username:              username,
            xms_mirid_token_field: xms_mirid_token_field_system_assigned_identity,
            oid_token_field:       oid_token_field
          )
        end
        it "raises an error" do
          expect { subject }.to raise_error(::Errors::Authentication::AuthnAzure::RoleMissingConstraint)
        end
      end

      context "that has invalid constraint combination in annotations" do
        before(:each) do
          allow(host).to receive(:annotations)
                           .and_return([subscription_id_annotation, resource_group_annotation, user_assigned_identity_annotation, system_assigned_identity_annotation])
        end
        subject do
          Authentication::AuthnAzure::ValidateApplicationIdentity.new(
            resource_class:             resource_class,
            validate_azure_annotations: validate_azure_annotations,
          ).call(
            account:               account,
            service_id:            service_id,
            username:              username,
            xms_mirid_token_field: xms_mirid_token_field_system_assigned_identity,
            oid_token_field:       oid_token_field
          )
        end

        it "raise an error" do
          expect { subject }.to raise_error(::Errors::Authentication::IllegalConstraintCombinations)
        end
      end

      context "that has invalid Azure annotations" do
        before(:each) do
          allow(host).to receive(:annotations)
                           .and_return([subscription_id_annotation, resource_group_annotation, system_assigned_identity_annotation])

          allow(validate_azure_annotations).to receive(:call)
                                                 .and_raise('FAKE_VALIDATE_APPLICATION_IDENTITY_ERROR')
        end
        subject do
          Authentication::AuthnAzure::ValidateApplicationIdentity.new(
            resource_class:             resource_class,
            validate_azure_annotations: validate_azure_annotations,
          ).call(
            account:               account,
            service_id:            service_id,
            username:              username,
            xms_mirid_token_field: xms_mirid_token_field_system_assigned_identity,
            oid_token_field:       oid_token_field
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(
                                  /FAKE_VALIDATE_APPLICATION_IDENTITY_ERROR/
                                )
        end
      end
    end
  end

  context "an invalid xms_mirid claim in the Azure token" do
    context "that does not begin with a /" do
      subject do
        Authentication::AuthnAzure::ValidateApplicationIdentity.new(
          resource_class:             resource_class,
          validate_azure_annotations: validate_azure_annotations,
        ).call(
          account:               account,
          service_id:            service_id,
          username:              username,
          xms_mirid_token_field: xms_mirid_token_missing_initial_slash,
          oid_token_field:       oid_token_field
        )
      end
      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end

    context "that is missing subscriptions field in xms_mirid" do
      subject do
        Authentication::AuthnAzure::ValidateApplicationIdentity.new(
          resource_class:             resource_class,
          validate_azure_annotations: validate_azure_annotations,
        ).call(
          account:               account,
          service_id:            service_id,
          username:              username,
          xms_mirid_token_field: xms_mirid_token_missing_subscription_id_field,
          oid_token_field:       oid_token_field
        )
      end
      it "raises an error" do
        expect { subject }.to raise_error(::Errors::Authentication::AuthnAzure::MissingRequiredFieldsInXmsMirid)
      end

    end

    context "that is missing resource groups field in xms_mirid" do
      subject do
        Authentication::AuthnAzure::ValidateApplicationIdentity.new(
          resource_class:             resource_class,
          validate_azure_annotations: validate_azure_annotations,
        ).call(
          account:               account,
          service_id:            service_id,
          username:              username,
          xms_mirid_token_field: xms_mirid_token_missing_resource_groups_field,
          oid_token_field:       oid_token_field
        )
      end
      it "raises an error" do
        expect { subject }.to raise_error(::Errors::Authentication::AuthnAzure::MissingRequiredFieldsInXmsMirid)
      end

    end

    context "that is missing providers field in xms_mirid" do
      subject do
        Authentication::AuthnAzure::ValidateApplicationIdentity.new(
          resource_class:             resource_class,
          validate_azure_annotations: validate_azure_annotations,
        ).call(
          account:               account,
          service_id:            service_id,
          username:              username,
          xms_mirid_token_field: xms_mirid_token_missing_providers_field,
          oid_token_field:       oid_token_field
        )
      end
      it "raises an error" do
        expect { subject }.to raise_error(::Errors::Authentication::AuthnAzure::MissingRequiredFieldsInXmsMirid)
      end

    end

    context "without the proper number of fields in the providers claim" do
      subject do
        Authentication::AuthnAzure::ValidateApplicationIdentity.new(
          resource_class:             resource_class,
          validate_azure_annotations: validate_azure_annotations,
        ).call(
          account:               account,
          service_id:            service_id,
          username:              username,
          xms_mirid_token_field: invalid_xms_mirid_token_providers_field,
          oid_token_field:       oid_token_field
        )
      end
      it "raises an error" do
        expect { subject }.to raise_error(::Errors::Authentication::AuthnAzure::MissingProviderFieldsInXmsMirid)
      end
    end
  end
end





