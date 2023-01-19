# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::AuthnGcp::ValidateResourceRestrictions' do

  let(:valid_account) { 'valid-account' }
  let(:authenticator_name) { 'authn-gcp' }
  let(:valid_host) { 'valid-host' }

  let(:gcp_instance_name_restriction_type) { 'authn-gcp/instance-name' }
  let(:gcp_instance_name_restriction_valid_value) { 'instance-name' }
  let(:gcp_instance_name_restriction_invalid_value) { 'invalid-instance-name' }
  let(:gcp_project_id_restriction_type) { 'authn-gcp/project-id' }
  let(:gcp_project_id_restriction_valid_value) { 'project-id' }
  let(:gcp_project_id_restriction_invalid_value) { 'invalid-project-id' }
  let(:gcp_service_account_id_restriction_type) { 'authn-gcp/service-account-id' }
  let(:gcp_service_account_id_restriction_valid_value) { 'service account id' }
  let(:gcp_service_account_id_restriction_invalid_value) { 'invalid service account id' }
  let(:gcp_service_account_email_restriction_type) { 'authn-gcp/service-account-email' }
  let(:gcp_service_account_email_restriction_valid_value) { 'service-account-email' }
  let(:gcp_service_account_email_restriction_invalid_value) { 'service_account_email is invalid' }
  let(:invalid_gcp_restriction_type) { 'invalid-gcp-restriction-type' }
  let(:invalid_gcp_restriction_value) { 'invalid-gcp-restriction-value' }

  let(:mocked_decoded_token_class_return_valid_values) { double("DecodedToken") }

  let(:mocked_resource_restrictions_return_all_valid_permitted_restrictions) { double("ResourceRestrictions") }
  let(:mocked_resource_restrictions_return_all_valid_permitted_restrictions_and_1_illegal) { double("ResourceRestrictions") }
  let(:mocked_resource_restrictions_return_all_permitted_restrictions_with_invalid_values) { double("ResourceRestrictions") }

  let(:resource_restrictions_with_all_valid_permitted_restrictions) {
    [
      Authentication::AuthnGcp::ResourceRestriction.new(
        type:  gcp_instance_name_restriction_type,
        value: gcp_instance_name_restriction_valid_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type:  gcp_project_id_restriction_type,
        value: gcp_project_id_restriction_valid_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type:  gcp_service_account_id_restriction_type,
        value: gcp_service_account_id_restriction_valid_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type:  gcp_service_account_email_restriction_type,
        value: gcp_service_account_email_restriction_valid_value
      )
    ]
  }

  let(:resource_restrictions_with_all_valid_permitted_restrictions_and_1_illegal) {
    [
      Authentication::AuthnGcp::ResourceRestriction.new(
        type:  gcp_instance_name_restriction_type,
        value: gcp_instance_name_restriction_valid_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type:  gcp_project_id_restriction_type,
        value: gcp_project_id_restriction_valid_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type:  gcp_service_account_id_restriction_type,
        value: gcp_service_account_id_restriction_valid_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type:  gcp_service_account_email_restriction_type,
        value: gcp_service_account_email_restriction_valid_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type:  invalid_gcp_restriction_type,
        value: invalid_gcp_restriction_value
      )
    ]
  }

  let(:resource_restrictions_with_all_permitted_restrictions_with_invalid_values) {
    [
      Authentication::AuthnGcp::ResourceRestriction.new(
        type:  gcp_instance_name_restriction_type,
        value: gcp_instance_name_restriction_invalid_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type:  gcp_project_id_restriction_type,
        value: gcp_project_id_restriction_invalid_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type:  gcp_service_account_id_restriction_type,
        value: gcp_service_account_id_restriction_invalid_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type:  gcp_service_account_email_restriction_type,
        value: gcp_service_account_email_restriction_invalid_value
      )
    ]
  }

  before(:each) do
    allow(mocked_decoded_token_class_return_valid_values).to receive(:project_id)
                                                               .and_return(gcp_project_id_restriction_valid_value)
    allow(mocked_decoded_token_class_return_valid_values).to receive(:instance_name)
                                                               .and_return(gcp_instance_name_restriction_valid_value)
    allow(mocked_decoded_token_class_return_valid_values).to receive(:service_account_id)
                                                               .and_return(gcp_service_account_id_restriction_valid_value)
    allow(mocked_decoded_token_class_return_valid_values).to receive(:service_account_email)
                                                               .and_return(gcp_service_account_email_restriction_valid_value)

    allow(mocked_resource_restrictions_return_all_valid_permitted_restrictions).to receive(:call)
                                                                                     .and_return(resource_restrictions_with_all_valid_permitted_restrictions)
    allow(mocked_resource_restrictions_return_all_valid_permitted_restrictions_and_1_illegal).to receive(:call)
                                                                                                   .and_return(resource_restrictions_with_all_valid_permitted_restrictions_and_1_illegal)
    allow(mocked_resource_restrictions_return_all_permitted_restrictions_with_invalid_values).to receive(:call)
                                                                                                   .and_return(resource_restrictions_with_all_permitted_restrictions_with_invalid_values)

  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "A valid resource restrictions configuration" do
    context "when all resource restrictions values exists in GCP token" do
      subject do
        ::Authentication::AuthnGcp::ValidateResourceRestrictions.new(
          extract_resource_restrictions: mocked_resource_restrictions_return_all_valid_permitted_restrictions
        ).call(
          authenticator_name: authenticator_name,
          account:            valid_account,
          username:           valid_host,
          credentials:        mocked_decoded_token_class_return_valid_values
        )
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end
  end

  context "An invalid resource restrictions configuration" do
    context "when resource restrictions contains illegal constraints" do
      subject do
        ::Authentication::AuthnGcp::ValidateResourceRestrictions.new(
          extract_resource_restrictions: mocked_resource_restrictions_return_all_valid_permitted_restrictions_and_1_illegal
        ).call(
          authenticator_name: authenticator_name,
          account:            valid_account,
          username:           valid_host,
          credentials:        mocked_decoded_token_class_return_valid_values
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::ConstraintNotSupported)
      end
    end

    context "when resource restrictions values do not match JWT token" do
      subject do
        ::Authentication::AuthnGcp::ValidateResourceRestrictions.new(
          extract_resource_restrictions: mocked_resource_restrictions_return_all_permitted_restrictions_with_invalid_values
        ).call(
          authenticator_name: authenticator_name,
          account:            valid_account,
          username:           valid_host,
          credentials:        mocked_decoded_token_class_return_valid_values
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(Errors::Authentication::Jwt::InvalidResourceRestrictions)
      end
    end
  end
end
