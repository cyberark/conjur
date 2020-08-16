# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::AuthnGCP::ValidateResourceRestrictionsConfiguration' do

  let(:gcp_instance_name_annotation_key) {'authn-gcp/instance-name'}
  let(:gcp_instance_name_annotation_value) {'instance-name'}
  let(:gcp_project_id_annotation_key) {'authn-gcp/project-id'}
  let(:gcp_project_id_annotation_value) {'project-id'}
  let(:gcp_service_account_id_annotation_key) {'authn-gcp/service-account-id'}
  let(:gcp_service_account_id_annotation_value) {'service account id'}
  let(:gcp_service_account_email_annotation_key) {'authn-gcp/service-account-email'}
  let(:gcp_service_account_email_annotation_value) {'service_account_email'}
  let(:invalid_gcp_annotation_key) {'authn-gcp/illegal gcp key'}
  let(:invalid_gcp_annotation_value) {'not authn-gcp/'}
  let(:empty_annotation_key) {''}
  let(:empty_annotation_value) {''}
  let(:nil_annotation_key) {nil}
  let(:nil_annotation_value) {nil}

  let(:gcp_permitted_constraints) {
    [
      gcp_instance_name_annotation_key,
      gcp_project_id_annotation_key,
      gcp_service_account_id_annotation_key,
      gcp_service_account_email_annotation_key
    ]
  }

  let(:gcp_permitted_constraints_with_duplications) {
    [
      gcp_instance_name_annotation_key,
      gcp_project_id_annotation_key,
      gcp_service_account_id_annotation_key,
      gcp_service_account_email_annotation_key,
      gcp_instance_name_annotation_key
    ]
  }

  let(:resource_restrictions_with_1_valid) {
    [
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_instance_name_annotation_key,
        value: gcp_instance_name_annotation_value
      )
    ]
  }

  let(:resource_restrictions_with_4_valid) {
    [
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_instance_name_annotation_key,
        value: gcp_instance_name_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_project_id_annotation_key,
        value: gcp_project_id_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_service_account_id_annotation_key,
        value: gcp_service_account_id_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_service_account_email_annotation_key,
        value: gcp_service_account_email_annotation_value
      )
    ]
  }

  let(:resource_restrictions_with_1_illegal) {
    [
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: invalid_gcp_annotation_key,
        value: invalid_gcp_annotation_value
      )
    ]
  }

  let(:resource_restrictions_with_4_valid_and_1_illegal) {
    [
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_instance_name_annotation_key,
        value: gcp_instance_name_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_project_id_annotation_key,
        value: gcp_project_id_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_service_account_id_annotation_key,
        value: gcp_service_account_id_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_service_account_email_annotation_key,
        value: gcp_service_account_email_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: invalid_gcp_annotation_key,
        value: invalid_gcp_annotation_value
      )
    ]
  }

  let(:resource_restrictions_with_empty_values) {
    [
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_instance_name_annotation_key,
        value: empty_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_project_id_annotation_key,
        value: empty_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_service_account_id_annotation_key,
        value: empty_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_service_account_email_annotation_key,
        value: empty_annotation_value
      )
    ]
  }

  let(:resource_restrictions_with_nil_values) {
    [
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_instance_name_annotation_key,
        value: nil_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_project_id_annotation_key,
        value: nil_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_service_account_id_annotation_key,
        value: nil_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_service_account_email_annotation_key,
        value: nil_annotation_value
      )
    ]
  }

  let(:resource_restrictions_with_empty_types) {
    [
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: empty_annotation_key,
        value: gcp_instance_name_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: empty_annotation_key,
        value: gcp_project_id_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: empty_annotation_key,
        value: gcp_service_account_id_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: empty_annotation_key,
        value: gcp_service_account_email_annotation_value
      )
    ]
  }

  let(:resource_restrictions_with_nil_types) {
    [
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: nil_annotation_key,
        value: gcp_instance_name_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: nil_annotation_key,
        value: gcp_project_id_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: nil_annotation_key,
        value: gcp_service_account_id_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: nil_annotation_key,
        value: gcp_service_account_email_annotation_value
      )
    ]
  }

  let(:resource_restrictions_with_duplicated_types) {
    [
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_instance_name_annotation_key,
        value: gcp_instance_name_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_project_id_annotation_key,
        value: gcp_project_id_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_service_account_id_annotation_key,
        value: gcp_service_account_id_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_service_account_email_annotation_key,
        value: gcp_service_account_email_annotation_value
      ),
      Authentication::AuthnGCP::ResourceRestriction.new(
        type: gcp_instance_name_annotation_key,
        value: gcp_instance_name_annotation_value
      )
    ]
  }

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "A valid resource restrictions list" do
    context "permitted constraints are 4 gcp values" do
      context "when resource restrictions list contains 1 valid restriction" do
        subject do
          Authentication::AuthnGCP::ValidateResourceRestrictionsConfiguration.new.call(
            resource_restrictions: resource_restrictions_with_1_valid,
            permitted_constraints: gcp_permitted_constraints
          )
        end

        it "does not raise an error" do
          expect {subject}.to_not raise_error
        end
      end

      context "when resource restrictions list contains 4 valid restrictions" do
        subject do
          Authentication::AuthnGCP::ValidateResourceRestrictionsConfiguration.new.call(
            resource_restrictions: resource_restrictions_with_4_valid,
            permitted_constraints: gcp_permitted_constraints
          )
        end

        it "does not raise an error" do
          expect {subject}.to_not raise_error
        end
      end
    end
  end

  context "An invalid resource restrictions list" do
    context "permitted constraints are 4 gcp values" do
      context "when resource restrictions list is empty" do
        subject do
          Authentication::AuthnGCP::ValidateResourceRestrictionsConfiguration.new.call(
            resource_restrictions: Array.new,
            permitted_constraints: gcp_permitted_constraints
          )
        end

        it "raises an error" do
          expect {subject}.to raise_error(Errors::Authentication::AuthnGcp::RoleMissingRequiredConstraints)
        end
      end

      context "when resource restrictions list is nil" do
        subject do
          Authentication::AuthnGCP::ValidateResourceRestrictionsConfiguration.new.call(
            resource_restrictions: nil,
            permitted_constraints: gcp_permitted_constraints
          )
        end

        it "raises an error" do
          expect {subject}.to raise_error(Errors::Authentication::AuthnGcp::RoleMissingRequiredConstraints)
        end
      end

      context "when resource restrictions contains illegal constraints" do
        context "with 1 illegal restriction" do
          subject do
            Authentication::AuthnGCP::ValidateResourceRestrictionsConfiguration.new.call(
              resource_restrictions: resource_restrictions_with_1_illegal,
              permitted_constraints: gcp_permitted_constraints
            )
          end

          it "raises an error" do
            expect {subject}.to raise_error(Errors::Authentication::ConstraintNotSupported)
          end
        end

        context "with 4 valid and 1 illegal restriction" do
          subject do
            Authentication::AuthnGCP::ValidateResourceRestrictionsConfiguration.new.call(
              resource_restrictions: resource_restrictions_with_4_valid_and_1_illegal,
              permitted_constraints: gcp_permitted_constraints
            )
          end

          it "raises an error" do
            expect {subject}.to raise_error(Errors::Authentication::ConstraintNotSupported)
          end
        end
      end

      context "when resource restrictions contains empty values" do
        subject do
          Authentication::AuthnGCP::ValidateResourceRestrictionsConfiguration.new.call(
            resource_restrictions: resource_restrictions_with_empty_values,
            permitted_constraints: gcp_permitted_constraints
          )
        end

        it "raises an error" do
          expect {subject}.to raise_error(Errors::Authentication::MissingResourceRestrictionsValue)
        end
      end

      context "when resource restrictions contains nil values" do
        subject do
          Authentication::AuthnGCP::ValidateResourceRestrictionsConfiguration.new.call(
            resource_restrictions: resource_restrictions_with_nil_values,
            permitted_constraints: gcp_permitted_constraints
          )
        end

        it "raises an error" do
          expect {subject}.to raise_error(Errors::Authentication::MissingResourceRestrictionsValue)
        end
      end
    end
  end
end
