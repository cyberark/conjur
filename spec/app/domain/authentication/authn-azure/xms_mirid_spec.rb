# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::AuthnAzure::XmsMirid' do

  let(:xms_mirid_token_field) {
    "/subscriptions/some-subscription-id-value/resourcegroups/" \
      "some-resource-group-value/providers/Microsoft.Compute/" \
      "virtualMachines/some-system-assigned-identity-value"
  }

  let(:xms_mirid_token_missing_subscription_id_field) {
    "/resourcegroups/some-resource-group-value/providers/" \
      "Microsoft.ManagedIdentity/userAssignedIdentities/" \
      "some-system-assigned-identity-value"
  }

  let(:xms_mirid_token_missing_resource_groups_field) {
    "/subscriptions/some-subscription-id-value/providers/" \
      "Microsoft.ManagedIdentity/some-user-assigned-identity-value"
  }

  let(:xms_mirid_token_missing_providers_field) {
    "/subscriptions/some-subscription-id-value/resourcegroups/" \
      "some-resource-group-value/"
  }

  let(:xms_mirid_token_missing_initial_slash) {
    "subscriptions/some-subscription-id-value/resourcegroups/" \
      "some-resource-group-value/providers/Microsoft.ManagedIdentity/" \
      "userAssignedIdentities/some-system-assigned-identity-value"
  }

  let(:invalid_xms_mirid_token_providers_field) {
    "/subscriptions/some-subscription-id-value/resourcegroups/" \
      "some-resource-group-value/providers/Microsoft.ManagedIdentity/" \
      "some-user-assigned-identity-value"
  }

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "A valid xms_mirid claim in the Azure token" do
    subject do
      Authentication::AuthnAzure::XmsMirid.new(
        xms_mirid_token_field
      )
    end

    it "does not raise an error" do
      expect { subject }.to_not raise_error
    end

    context "where the xms mirid claim does not begin with a /" do
      subject do
        Authentication::AuthnAzure::XmsMirid.new(
          xms_mirid_token_missing_initial_slash
        )
      end
      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end
  end

  context "An invalid xms_mirid claim in the Azure token" do
    context "that is missing subscriptions field in xms_mirid" do
      subject do
        Authentication::AuthnAzure::XmsMirid.new(
          xms_mirid_token_missing_subscription_id_field
        )
      end
      it "raises an error" do
        expect { subject }.to raise_error(
          ::Errors::Authentication::AuthnAzure::MissingRequiredFieldsInXmsMirid
        )
      end

    end

    context "that is missing resource groups field in xms_mirid" do
      subject do
        Authentication::AuthnAzure::XmsMirid.new(
          xms_mirid_token_missing_resource_groups_field
        )
      end
      it "raises an error" do
        expect { subject }.to raise_error(
          ::Errors::Authentication::AuthnAzure::MissingRequiredFieldsInXmsMirid
        )
      end

    end

    context "that is missing providers field in xms_mirid" do
      subject do
        Authentication::AuthnAzure::XmsMirid.new(
          xms_mirid_token_missing_providers_field
        )
      end
      it "raises an error" do
        expect { subject }.to raise_error(
          ::Errors::Authentication::AuthnAzure::MissingRequiredFieldsInXmsMirid
        )
      end

    end

    context "without the proper number of fields in the providers claim" do
      subject do
        Authentication::AuthnAzure::XmsMirid.new(
          invalid_xms_mirid_token_providers_field
        )
      end
      it "raises an error" do
        expect { subject }.to raise_error(::Errors::Authentication::AuthnAzure::InvalidProviderFieldsInXmsMirid)
      end
    end
  end
end
