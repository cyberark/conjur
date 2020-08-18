# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::AuthnGce::ValidateResourceRestrictionsConfiguration' do

  let(:gce_instance_name_annotation_key) {'authn-gce/instance-name'}
  let(:gce_instance_name_annotation_value) {'instance-name'}
  let(:gce_project_id_annotation_key) {'authn-gce/project-id'}
  let(:gce_project_id_annotation_value) {'project-id'}
  let(:gce_service_account_id_annotation_key) {'authn-gce/service-account-id'}
  let(:gce_service_account_id_annotation_value) {'service account id'}
  let(:gce_service_account_email_annotation_key) {'authn-gce/service-account-email'}
  let(:gce_service_account_email_annotation_value) {'service_account_email'}
  let(:invalid_gce_annotation_key) {'authn-gce/illegal gce key'}
  let(:invalid_gce_annotation_value) {'not authn-gce/'}
  let(:empty_annotation_key) {''}
  let(:empty_annotation_value) {''}
  let(:nil_annotation_key) {nil}
  let(:nil_annotation_value) {nil}

  let(:gce_permitted_constraints) {
    [
      gce_instance_name_annotation_key,
      gce_project_id_annotation_key,
      gce_service_account_id_annotation_key,
      gce_service_account_email_annotation_key
    ]
  }

  let(:gce_permitted_constraints_with_duplications) {
    [
      gce_instance_name_annotation_key,
      gce_project_id_annotation_key,
      gce_service_account_id_annotation_key,
      gce_service_account_email_annotation_key,
      gce_instance_name_annotation_key
    ]
  }

  let(:resource_restrictions_with_1_valid) {
    [
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_instance_name_annotation_key,
        value: gce_instance_name_annotation_value
      )
    ]
  }

  let(:resource_restrictions_with_4_valid) {
    [
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_instance_name_annotation_key,
        value: gce_instance_name_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_project_id_annotation_key,
        value: gce_project_id_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_id_annotation_key,
        value: gce_service_account_id_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_email_annotation_key,
        value: gce_service_account_email_annotation_value
      )
    ]
  }

  let(:resource_restrictions_with_1_illegal) {
    [
      Authentication::AuthnGce::ResourceRestriction.new(
        type: invalid_gce_annotation_key,
        value: invalid_gce_annotation_value
      )
    ]
  }

  let(:resource_restrictions_with_4_valid_and_1_illegal) {
    [
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_instance_name_annotation_key,
        value: gce_instance_name_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_project_id_annotation_key,
        value: gce_project_id_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_id_annotation_key,
        value: gce_service_account_id_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_email_annotation_key,
        value: gce_service_account_email_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: invalid_gce_annotation_key,
        value: invalid_gce_annotation_value
      )
    ]
  }

  let(:resource_restrictions_with_empty_values) {
    [
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_instance_name_annotation_key,
        value: empty_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_project_id_annotation_key,
        value: empty_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_id_annotation_key,
        value: empty_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_email_annotation_key,
        value: empty_annotation_value
      )
    ]
  }

  let(:resource_restrictions_with_nil_values) {
    [
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_instance_name_annotation_key,
        value: nil_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_project_id_annotation_key,
        value: nil_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_id_annotation_key,
        value: nil_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_email_annotation_key,
        value: nil_annotation_value
      )
    ]
  }

  let(:resource_restrictions_with_empty_types) {
    [
      Authentication::AuthnGce::ResourceRestriction.new(
        type: empty_annotation_key,
        value: gce_instance_name_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: empty_annotation_key,
        value: gce_project_id_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: empty_annotation_key,
        value: gce_service_account_id_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: empty_annotation_key,
        value: gce_service_account_email_annotation_value
      )
    ]
  }

  let(:resource_restrictions_with_nil_types) {
    [
      Authentication::AuthnGce::ResourceRestriction.new(
        type: nil_annotation_key,
        value: gce_instance_name_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: nil_annotation_key,
        value: gce_project_id_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: nil_annotation_key,
        value: gce_service_account_id_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: nil_annotation_key,
        value: gce_service_account_email_annotation_value
      )
    ]
  }

  let(:resource_restrictions_with_duplicated_types) {
    [
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_instance_name_annotation_key,
        value: gce_instance_name_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_project_id_annotation_key,
        value: gce_project_id_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_id_annotation_key,
        value: gce_service_account_id_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_service_account_email_annotation_key,
        value: gce_service_account_email_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_instance_name_annotation_key,
        value: gce_instance_name_annotation_value
      )
    ]
  }

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "A valid resource restrictions list" do
    context "permitted constraints are 4 gce values" do
      context "when resource restrictions list contains 1 valid restriction" do
        subject do
          Authentication::AuthnGce::ValidateResourceRestrictionsConfiguration.new.call(
            resource_restrictions: resource_restrictions_with_1_valid,
            permitted_constraints: gce_permitted_constraints
          )
        end

        it "does not raise an error" do
          expect {subject}.to_not raise_error
        end
      end

      context "when resource restrictions list contains 4 valid restrictions" do
        subject do
          Authentication::AuthnGce::ValidateResourceRestrictionsConfiguration.new.call(
            resource_restrictions: resource_restrictions_with_4_valid,
            permitted_constraints: gce_permitted_constraints
          )
        end

        it "does not raise an error" do
          expect {subject}.to_not raise_error
        end
      end
    end
  end

  context "An invalid resource restrictions list" do
    context "permitted constraints are 4 gce values" do
      context "when resource restrictions list is empty" do
        subject do
          Authentication::AuthnGce::ValidateResourceRestrictionsConfiguration.new.call(
            resource_restrictions: Array.new,
            permitted_constraints: gce_permitted_constraints
          )
        end

        it "raises an error" do
          expect {subject}.to raise_error(Errors::Authentication::AuthnGce::RoleMissingRequiredConstraints)
        end
      end

      context "when resource restrictions list is nil" do
        subject do
          Authentication::AuthnGce::ValidateResourceRestrictionsConfiguration.new.call(
            resource_restrictions: nil,
            permitted_constraints: gce_permitted_constraints
          )
        end

        it "raises an error" do
          expect {subject}.to raise_error(Errors::Authentication::AuthnGce::RoleMissingRequiredConstraints)
        end
      end

      context "when resource restrictions contains illegal constraints" do
        context "with 1 illegal restriction" do
          subject do
            Authentication::AuthnGce::ValidateResourceRestrictionsConfiguration.new.call(
              resource_restrictions: resource_restrictions_with_1_illegal,
              permitted_constraints: gce_permitted_constraints
            )
          end

          it "raises an error" do
            expect {subject}.to raise_error(Errors::Authentication::ConstraintNotSupported)
          end
        end

        context "with 4 valid and 1 illegal restriction" do
          subject do
            Authentication::AuthnGce::ValidateResourceRestrictionsConfiguration.new.call(
              resource_restrictions: resource_restrictions_with_4_valid_and_1_illegal,
              permitted_constraints: gce_permitted_constraints
            )
          end

          it "raises an error" do
            expect {subject}.to raise_error(Errors::Authentication::ConstraintNotSupported)
          end
        end
      end

      context "when resource restrictions contains empty values" do
        subject do
          Authentication::AuthnGce::ValidateResourceRestrictionsConfiguration.new.call(
            resource_restrictions: resource_restrictions_with_empty_values,
            permitted_constraints: gce_permitted_constraints
          )
        end

        it "raises an error" do
          expect {subject}.to raise_error(Errors::Authentication::MissingResourceRestrictionsValue)
        end
      end

      context "when resource restrictions contains nil values" do
        subject do
          Authentication::AuthnGce::ValidateResourceRestrictionsConfiguration.new.call(
            resource_restrictions: resource_restrictions_with_nil_values,
            permitted_constraints: gce_permitted_constraints
          )
        end

        it "raises an error" do
          expect {subject}.to raise_error(Errors::Authentication::MissingResourceRestrictionsValue)
        end
      end
    end
  end
end
