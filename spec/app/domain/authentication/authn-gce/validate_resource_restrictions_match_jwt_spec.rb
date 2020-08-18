# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::AuthnGce::ValidateResourceRestrictionsMatchJWT' do

  let(:gce_restriction_prefix) {'authn-gce/'}

  let(:gce_instance_name_restriction_type) {'authn-gce/instance-name'}
  let(:gce_instance_name_restriction_valid_value) {'instance-name'}
  let(:gce_instance_name_restriction_invalid_value) {'invalid-instance-name'}
  let(:gce_project_id_restriction_type) {'authn-gce/project-id'}
  let(:gce_project_id_restriction_valid_value) {'project-id'}
  let(:gce_project_id_restriction_invalid_value) {'invalid-project-id'}
  let(:gce_service_account_id_restriction_type) {'authn-gce/service-account-id'}
  let(:gce_service_account_id_restriction_valid_value) {'service account id'}
  let(:gce_service_account_id_restriction_invalid_value) {'invalid service account id'}
  let(:gce_service_account_email_restriction_type) {'authn-gce/service-account-email'}
  let(:gce_service_account_email_restriction_valid_value) {'service-account-email'}
  let(:gce_service_account_email_restriction_invalid_value) {'service_account_email is invalid'}

  let(:resource_restrictions_with_4_valid) {
    [
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_instance_name_restriction_type,
        value: gce_instance_name_restriction_valid_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_project_id_restriction_type,
        value: gce_project_id_restriction_valid_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_id_restriction_type,
        value: gce_service_account_id_restriction_valid_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_email_restriction_type,
        value: gce_service_account_email_restriction_valid_value
      )
    ]
  }

  let(:resource_restrictions_with_1_valid_instance_name) {
    [
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_instance_name_restriction_type,
        value: gce_instance_name_restriction_valid_value
      )
    ]
  }

  let(:resource_restrictions_with_1_valid_project_id) {
    [
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_project_id_restriction_type,
        value: gce_project_id_restriction_valid_value
      )
    ]
  }

  let(:resource_restrictions_with_1_valid_service_account_id) {
    [
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_id_restriction_type,
        value: gce_service_account_id_restriction_valid_value
      )
    ]
  }

  let(:resource_restrictions_with_1_valid_service_account_email) {
    [
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_email_restriction_type,
        value: gce_service_account_email_restriction_valid_value
      )
    ]
  }

  let(:resource_restrictions_with_only_instance_name_invalid) {
    [
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_instance_name_restriction_type,
        value: gce_instance_name_restriction_invalid_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_project_id_restriction_type,
        value: gce_project_id_restriction_valid_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_id_restriction_type,
        value: gce_service_account_id_restriction_valid_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_email_restriction_type,
        value: gce_service_account_email_restriction_valid_value
      )
    ]
  }

  let(:resource_restrictions_with_only_project_id_invalid) {
    [
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_instance_name_restriction_type,
        value: gce_instance_name_restriction_valid_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_project_id_restriction_type,
        value: gce_project_id_restriction_invalid_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_id_restriction_type,
        value: gce_service_account_id_restriction_valid_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_email_restriction_type,
        value: gce_service_account_email_restriction_valid_value
      )
    ]
  }

  let(:resource_restrictions_with_only_service_account_id_invalid) {
    [
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_instance_name_restriction_type,
        value: gce_instance_name_restriction_valid_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_project_id_restriction_type,
        value: gce_project_id_restriction_valid_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_id_restriction_type,
        value: gce_service_account_id_restriction_invalid_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_email_restriction_type,
        value: gce_service_account_email_restriction_valid_value
      )
    ]
  }

  let(:resource_restrictions_with_only_service_account_email_invalid) {
    [
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_instance_name_restriction_type,
        value: gce_instance_name_restriction_valid_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_project_id_restriction_type,
        value: gce_project_id_restriction_valid_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_id_restriction_type,
        value: gce_service_account_id_restriction_valid_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_email_restriction_type,
        value: gce_service_account_email_restriction_invalid_value
      )
    ]
  }


  let(:mocked_decoded_token_class_return_valid_values) {double("DecodedToken")}

  before(:each) do
    allow(mocked_decoded_token_class_return_valid_values).to receive(:project_id)
                                                               .and_return(gce_project_id_restriction_valid_value)
    allow(mocked_decoded_token_class_return_valid_values).to receive(:instance_name)
                                                               .and_return(gce_instance_name_restriction_valid_value)
    allow(mocked_decoded_token_class_return_valid_values).to receive(:service_account_id)
                                                               .and_return(gce_service_account_id_restriction_valid_value)
    allow(mocked_decoded_token_class_return_valid_values).to receive(:service_account_email)
                                                               .and_return(gce_service_account_email_restriction_valid_value)
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "A valid resource restrictions values" do
    context "when all resource restrictions are valid" do
      subject do
        Authentication::AuthnGce::ValidateResourceRestrictionsMatchJWT.new.call(
          resource_restrictions: resource_restrictions_with_4_valid,
          decoded_token:         mocked_decoded_token_class_return_valid_values,
          restriction_prefix:    gce_restriction_prefix
        )
      end

      it "does not raise an error" do
        expect {subject}.to_not raise_error
      end
    end

    context "when instance_name resource restrictions type is valid" do
      subject do
        Authentication::AuthnGce::ValidateResourceRestrictionsMatchJWT.new.call(
          resource_restrictions: resource_restrictions_with_1_valid_instance_name,
          decoded_token:         mocked_decoded_token_class_return_valid_values,
          restriction_prefix:    gce_restriction_prefix
        )
      end

      it "does not raise an error" do
        expect {subject}.to_not raise_error
      end
    end

    context "when project_id resource restrictions type is valid" do
      subject do
        Authentication::AuthnGce::ValidateResourceRestrictionsMatchJWT.new.call(
          resource_restrictions: resource_restrictions_with_1_valid_project_id,
          decoded_token:         mocked_decoded_token_class_return_valid_values,
          restriction_prefix:    gce_restriction_prefix
        )
      end

      it "does not raise an error" do
        expect {subject}.to_not raise_error
      end
    end

    context "when service_account_id resource restrictions type is valid" do
      subject do
        Authentication::AuthnGce::ValidateResourceRestrictionsMatchJWT.new.call(
          resource_restrictions: resource_restrictions_with_1_valid_service_account_id,
          decoded_token:         mocked_decoded_token_class_return_valid_values,
          restriction_prefix:    gce_restriction_prefix
        )
      end

      it "does not raise an error" do
        expect {subject}.to_not raise_error
      end
    end

    context "when service_account_email resource restrictions type is valid" do
      subject do
        Authentication::AuthnGce::ValidateResourceRestrictionsMatchJWT.new.call(
          resource_restrictions: resource_restrictions_with_1_valid_service_account_email,
          decoded_token:         mocked_decoded_token_class_return_valid_values,
          restriction_prefix:    gce_restriction_prefix
        )
      end

      it "does not raise an error" do
        expect {subject}.to_not raise_error
      end
    end
  end

  context "An invalid resource restrictions values" do
    context "when only instance_name resource restrictions type is invalid" do
      subject do
        Authentication::AuthnGce::ValidateResourceRestrictionsMatchJWT.new.call(
          resource_restrictions: resource_restrictions_with_only_instance_name_invalid,
          decoded_token:         mocked_decoded_token_class_return_valid_values,
          restriction_prefix:    gce_restriction_prefix
        )
      end

      it "raises an error" do
        expect {subject}.to raise_error(Errors::Authentication::Jwt::InvalidResourceRestrictions)
      end
    end

    context "when only project_id resource restrictions type is invalid" do
      subject do
        Authentication::AuthnGce::ValidateResourceRestrictionsMatchJWT.new.call(
          resource_restrictions: resource_restrictions_with_only_project_id_invalid,
          decoded_token:         mocked_decoded_token_class_return_valid_values,
          restriction_prefix:    gce_restriction_prefix
        )
      end

      it "raises an error" do
        expect {subject}.to raise_error(Errors::Authentication::Jwt::InvalidResourceRestrictions)
      end
    end

    context "when only service_account_id resource restrictions type is invalid" do
      subject do
        Authentication::AuthnGce::ValidateResourceRestrictionsMatchJWT.new.call(
          resource_restrictions: resource_restrictions_with_only_service_account_id_invalid,
          decoded_token:         mocked_decoded_token_class_return_valid_values,
          restriction_prefix:    gce_restriction_prefix
        )
      end

      it "raises an error" do
        expect {subject}.to raise_error(Errors::Authentication::Jwt::InvalidResourceRestrictions)
      end
    end

    context "when only service_account_email resource restrictions type is invalid" do
      subject do
        Authentication::AuthnGce::ValidateResourceRestrictionsMatchJWT.new.call(
          resource_restrictions: resource_restrictions_with_only_service_account_email_invalid,
          decoded_token:         mocked_decoded_token_class_return_valid_values,
          restriction_prefix:    gce_restriction_prefix
        )
      end

      it "raises an error" do
        expect {subject}.to raise_error(Errors::Authentication::Jwt::InvalidResourceRestrictions)
      end
    end
  end
end
