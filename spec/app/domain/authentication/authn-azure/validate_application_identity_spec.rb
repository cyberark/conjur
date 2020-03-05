# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::AuthnAzure::ValidateApplicationIdentity' do
  let(:account) { "account" }
  let(:service_id) { "serviceId" }
  let(:username) { "host/azureTestVM" }
  let(:hostname) { "azureTestVM" }

  let(:resource_class) { double("ResourceClass") }
  let(:mocked_host) { double "MockHost" }

  let(:xms_mirid_token_field_user_identity) { "/subscriptions/some-subscription-id-value/resourcegroups/some-resource-group-value/providers/Microsoft.ManagedIdentity/userAssignedIdentities/some-user-assigned-identity-value" }
  let(:xms_mirid_token_field_system_identity) { "/subscriptions/some-subscription-id-value/resourcegroups/some-resource-group-value/providers/Microsoft.Compute/virtualMachines/some-system-assigned-identity-value" }

  let(:xms_mirid_token_missing_subscription_field) { "/resourcegroups/some-resource-group-value/providers/Microsoft.ManagedIdentity/userAssignedIdentities/some-system-assigned-identity-value" }
  let(:xms_mirid_token_missing_resource_groups_field) { "/subscriptions/some-subscription-id-value/providers/Microsoft.ManagedIdentity/some-user-assigned-identity-value" }
  let(:xms_mirid_token_missing_providers_field) { "/subscriptions/some-subscription-id-value/resourcegroups/some-resource-group-value/" }

  let(:invalid_xms_mirid_token_provider_field) { "/subscriptions/some-subscription-id-value/resourcegroups/some-resource-group-value/providers/Microsoft.ManagedIdentity/some-user-assigned-identity-value" }

  let(:oid_token_field) { "test-oid" }

  let(:subscription_id_annotation) { double("SubscriptionIdAnnotation") }
  let(:resource_group_annotation) { double("ResourceGroupAnnotation") }
  let(:user_assigned_identity_annotation) { double("UserAssignedIdentityAnnotation") }
  let(:system_assigned_identity_annotation) { double("SystemAssignedIdentityAnnotation") }

  let(:mismatched_subscription_id_annotation) { double ("MismatchedSubscriptionIdAnnotation") }
  let(:mismatched_resource_group_annotation) { double ("MismatchedResourceGroupAnnotation") }
  let(:mismatched_system_assigned_identity_annotation) { double ("MismatchedSystemAssignedAnnotation") }
  let(:mismatched_user_assigned_identity_annotation) { double ("MismatchedUserAssignedAnnotation") }

  let(:invalid_azure_annotation) { double ("InvalidAzureAnnotation") }
  let(:validate_azure_annotations) { double("ValidateAzureAnnotations") }

  before(:each) do
    allow(mocked_host).to receive(:annotations)
                            .and_return([subscription_id_annotation, resource_group_annotation])

    allow(subscription_id_annotation).to receive(:values)
                                           .and_return(subscription_id_annotation)
    allow(subscription_id_annotation).to receive(:[])
                                           .with(:name)
                                           .and_return("authn-azure/subscription-id")
    allow(subscription_id_annotation).to receive(:[])
                                           .with(:value)
                                           .and_return("some-subscription-id-value")

    allow(resource_group_annotation).to receive(:values)
                                          .and_return(resource_group_annotation)
    allow(resource_group_annotation).to receive(:[])
                                          .with(:name)
                                          .and_return("authn-azure/resource-group")
    allow(resource_group_annotation).to receive(:[])
                                          .with(:value)
                                          .and_return("some-resource-group-value")

    allow(user_assigned_identity_annotation).to receive(:values)
                                                  .and_return(user_assigned_identity_annotation)
    allow(user_assigned_identity_annotation).to receive(:[])
                                                  .with(:name)
                                                  .and_return("authn-azure/user-assigned-identity")
    allow(user_assigned_identity_annotation).to receive(:[])
                                                  .with(:value)
                                                  .and_return("some-user-assigned-identity-value")

    allow(system_assigned_identity_annotation).to receive(:values)
                                                    .and_return(system_assigned_identity_annotation)
    allow(system_assigned_identity_annotation).to receive(:[])
                                                    .with(:name)
                                                    .and_return("authn-azure/system-assigned-identity")
    allow(system_assigned_identity_annotation).to receive(:[])
                                                    .with(:value)
                                                    .and_return(oid_token_field)

    allow(mismatched_subscription_id_annotation).to receive(:values)
                                                      .and_return(mismatched_subscription_id_annotation)
    allow(mismatched_subscription_id_annotation).to receive(:[])
                                                      .with(:name)
                                                      .and_return("authn-azure/subscription-id")
    allow(mismatched_subscription_id_annotation).to receive(:[])
                                                      .with(:value)
                                                      .and_return("mismatched-subscription-id")

    allow(mismatched_resource_group_annotation).to receive(:values)
                                                     .and_return(mismatched_resource_group_annotation)
    allow(mismatched_resource_group_annotation).to receive(:[])
                                                     .with(:name)
                                                     .and_return("authn-azure/resource-group")
    allow(mismatched_resource_group_annotation).to receive(:[])
                                                     .with(:value)
                                                     .and_return("mismatched-resource-group")

    allow(mismatched_system_assigned_identity_annotation).to receive(:values)
                                                               .and_return(mismatched_system_assigned_identity_annotation)
    allow(mismatched_system_assigned_identity_annotation).to receive(:[])
                                                               .with(:name)
                                                               .and_return("authn-azure/system-assigned-identity")
    allow(mismatched_system_assigned_identity_annotation).to receive(:[])
                                                               .with(:value)
                                                               .and_return("mismatched-system-assigned-identity")

    allow(mismatched_user_assigned_identity_annotation).to receive(:values)
                                                             .and_return(mismatched_user_assigned_identity_annotation)
    allow(mismatched_user_assigned_identity_annotation).to receive(:[])
                                                             .with(:name)
                                                             .and_return("authn-azure/user-assigned-identity")
    allow(mismatched_user_assigned_identity_annotation).to receive(:[])
                                                             .with(:value)
                                                             .and_return("mismatched-user-assigned-identity")

    allow(invalid_azure_annotation).to receive(:values)
                                         .and_return(subscription_id_annotation)
    allow(invalid_azure_annotation).to receive(:[])
                                         .with(:name)
                                         .and_return("authn-azure/test")

    allow(validate_azure_annotations).to receive(:call)
                                           .and_return(true)

    allow(resource_class).to receive(:[])
                               .with("#{account}:host:#{hostname}")
                               .and_return(mocked_host)
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "A valid xms_mirid claim in the Azure token" do
    context "A valid application identity" do
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
              xms_mirid_token_field: xms_mirid_token_field_system_identity,
              oid_token_field:       oid_token_field
            )
          end

          it "does not raise an error" do
            expect { subject }.to_not raise_error
          end
        end

        context "with a user assigned Azure identity in application identity" do
          before(:each) do
            allow(mocked_host).to receive(:annotations)
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
              xms_mirid_token_field: xms_mirid_token_field_user_identity,
              oid_token_field:       oid_token_field
            )
          end

          it "does not raise an error" do
            expect { subject }.to_not raise_error
          end
        end

        context "with a system assigned Azure identity in application identity" do
          before(:each) do
            allow(mocked_host).to receive(:annotations)
                                    .and_return([subscription_id_annotation, resource_group_annotation, system_assigned_identity_annotation])
          end
          subject do
            Authentication::AuthnAzure::ValidateApplicationIdentity.new(
              resource_class:             resource_class,
              validate_azure_annotations: validate_azure_annotations,
            ).call(
              account:               account,
              service_id:            service_id,
              username:              username,
              xms_mirid_token_field: xms_mirid_token_field_system_identity,
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
            allow(mocked_host).to receive(:annotations)
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
              xms_mirid_token_field: xms_mirid_token_field_system_identity,
              oid_token_field:       oid_token_field
            )
          end

          it "raises an error" do
            expect { subject }.to raise_error(::Errors::Authentication::AuthnAzure::InvalidApplicationIdentity)
          end
        end
        context "where the resource group does not match the application identity" do
          before(:each) do
            allow(mocked_host).to receive(:annotations)
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
              xms_mirid_token_field: xms_mirid_token_field_system_identity,
              oid_token_field:       oid_token_field
            )
          end

          it "raises an error" do
            expect { subject }.to raise_error(::Errors::Authentication::AuthnAzure::InvalidApplicationIdentity)
          end
        end

        context "where the user assigned identity does not match the application identity" do
          before(:each) do
            allow(mocked_host).to receive(:annotations)
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
              xms_mirid_token_field: xms_mirid_token_field_system_identity,
              oid_token_field:       oid_token_field
            )
          end

          it "raises an error" do
            expect { subject }.to raise_error(::Errors::Authentication::AuthnAzure::InvalidApplicationIdentity)
          end
        end

        context "where the system assigned identity does not match the application identity" do
          before(:each) do
            allow(mocked_host).to receive(:annotations)
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
              xms_mirid_token_field: xms_mirid_token_field_system_identity,
              oid_token_field:       oid_token_field
            )
          end

          it "raises an error" do
            expect { subject }.to raise_error(::Errors::Authentication::AuthnAzure::InvalidApplicationIdentity)
          end
        end

      end
    end

    context "An invalid application identity" do
      context "that does not have required constraints present in annotations" do
        before(:each) do
          allow(mocked_host).to receive(:annotations)
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
            xms_mirid_token_field: xms_mirid_token_field_system_identity,
            oid_token_field:       oid_token_field
          )
        end
        it "it raise an error" do
          expect { subject }.to raise_error(::Errors::Authentication::AuthnAzure::MissingConstraint)
        end
      end

      context "that has invalid constraint combination in annotations" do
        before(:each) do
          allow(mocked_host).to receive(:annotations)
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
            xms_mirid_token_field: xms_mirid_token_field_system_identity,
            oid_token_field:       oid_token_field
          )
        end

        it "raise an error" do
          expect { subject }.to raise_error(::Errors::Authentication::IllegalConstraintCombinations)
        end
      end

      context "that has invalid Azure annotations" do
        before(:each) do
          allow(mocked_host).to receive(:annotations)
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
            xms_mirid_token_field: xms_mirid_token_field_system_identity,
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

  context "An invalid xms_mirid claim in the Azure token" do
    context "that is missing subscriptions field in xms_mirid" do
      subject do
        Authentication::AuthnAzure::ValidateApplicationIdentity.new(
          resource_class:             resource_class,
          validate_azure_annotations: validate_azure_annotations,
        ).call(
          account:               account,
          service_id:            service_id,
          username:              username,
          xms_mirid_token_field: xms_mirid_token_missing_subscription_field,
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
          xms_mirid_token_field: invalid_xms_mirid_token_provider_field,
          oid_token_field:       oid_token_field
        )
      end
      it "it raise an error" do
        expect { subject }.to raise_error(::Errors::Authentication::AuthnAzure::MissingProviderFieldsInXmsMirid)
      end
    end
  end
end





