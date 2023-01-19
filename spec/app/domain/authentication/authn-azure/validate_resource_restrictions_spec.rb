# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::AuthnAzure::ValidateResourceRestrictions' do
  include_context "security mocks"

  let(:test_service_id) { "MockService" }

  let(:account) { "account" }

  let(:hostname) { "azureTestVM" }
  let(:username) { "host/#{hostname}" }

  let(:resource_class) { double("Resource") }
  let(:host) { double("some-host") }

  let(:non_existent_host_id) { double ("some-non-existent-host-id") }
  let(:xms_mirid_token_field_user_assigned_identity) { "/subscriptions/some-subscription-id-value/resourcegroups/some-resource-group-value/providers/Microsoft.ManagedIdentity/userAssignedIdentities/some-user-assigned-identity-value" }
  let(:xms_mirid_token_field_system_assigned_identity) { "/subscriptions/some-subscription-id-value/resourcegroups/some-resource-group-value/providers/Microsoft.Compute/virtualMachines/some-system-assigned-identity-value" }
  let(:xms_mirid_token_field_wrong_identity) { "/subscriptions/other-subscription-id-value/resourcegroups/other-resource-group-value/providers/Microsoft.Compute/virtualMachines/some-system-assigned-identity-value" }

  let(:oid_token_field) { "test-oid" }

  let(:resource_restrictions_class) { double("ResourceRestrictions") }

  let(:resource_restrictions) {
    [
      Authentication::AuthnAzure::AzureResource.new(
        type: "subscription-id",
        value: "some-subscription-id-value"
      ),
      Authentication::AuthnAzure::AzureResource.new(
        type: "resource-group",
        value: "some-resource-group-value"
      )
    ]
  }
  
  before(:each) do
    allow(host).to receive(:annotations)
                     .and_return("some annotations")

    allow(resource_class).to receive(:[])
                               .with("#{account}:host:#{hostname}")
                               .and_return(host)

    allow(resource_restrictions_class).to receive(:new)
                                            .and_return(resource_restrictions_class)

    allow(resource_restrictions_class).to receive(:resources)
                                            .and_return(resource_restrictions)
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "Resource restrictions" do
    context "with valid configuration" do
      context "that match request" do
        subject do
          Authentication::AuthnAzure::ValidateResourceRestrictions.new(
            resource_class:              resource_class,
            resource_restrictions_class: resource_restrictions_class,
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

      context "that does not match request" do
        subject do
          Authentication::AuthnAzure::ValidateResourceRestrictions.new(
            resource_class:              resource_class,
            resource_restrictions_class: resource_restrictions_class,
          ).call(
            account:               account,
            service_id:            test_service_id,
            username:              username,
            xms_mirid_token_field: xms_mirid_token_field_wrong_identity,
            oid_token_field:       oid_token_field
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(
            Errors::Authentication::Jwt::InvalidResourceRestrictions
          )
        end
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
        resource_class:              resource_class,
        resource_restrictions_class: resource_restrictions_class,
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
