# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::AuthnGce::ExtractResourceRestrictions' do

  include_context "security mocks"

  let(:valid_account) {'valid-account'}
  let(:invalid_account) {'invalid-account'}

  let(:valid_host) {'valid-host'}
  let(:invalid_host) {'invalid-host'}

  let(:valid_prefix) {'authn-gce/'}
  let(:empty_prefix) {''}
  let(:case_sensitive_prefix) {'authn-GCE/'}
  let(:without_slash_prefix) {'authn-gce'}

  let(:gce_instance_name_annotation_key) {'authn-gce/instance-name'}
  let(:gce_instance_name_annotation_value) {'instance-name'}
  let(:gce_project_id_annotation_key) {'authn-gce/project-id'}
  let(:gce_project_id_annotation_value) {'project-id'}
  let(:gce_service_account_id_annotation_key) {'authn-gce/service-account-id'}
  let(:gce_service_account_id_annotation_value) {'service account id'}
  let(:gce_service_account_email_annotation_key) {'authn-gce/service-account-email'}
  let(:gce_service_account_email_annotation_value) {'service_account_email'}
  let(:description_annotation_key) {'description'}
  let(:description_annotation_value) {'this is the best gce host in Conjur'}
  let(:upper_case_annotation_key) {'authn-GCE/'}
  let(:upper_case_annotation_value) {'not authn-gce/'}
  let(:invalid_gce_annotation_key) {'authn-gce'}
  let(:invalid_gce_annotation_value) {'not authn-gce/'}
  let(:empty_gce_key_annotation_key) {'authn-gce/'}
  let(:empty_gce_key_annotation_value) {'empty key prefix'}
  let(:empty_gce_val_annotation_key) {'authn-gce/empty-val'}
  let(:empty_gce_val_annotation_value) {''}

  class MockAnnotation
    def initialize(name, value)
      @values = {name: name, value: value}
    end

    def values
      @values
    end

    def [](*key)
      return @values[:value] if key.to_s == '[:value]'
    end
  end

  let(:annotations_list) {
    [
      MockAnnotation.new(gce_instance_name_annotation_key, gce_instance_name_annotation_value),
      MockAnnotation.new(gce_project_id_annotation_key, gce_project_id_annotation_value),
      MockAnnotation.new(gce_service_account_id_annotation_key, gce_service_account_id_annotation_value),
      MockAnnotation.new(gce_service_account_email_annotation_key, gce_service_account_email_annotation_value),
      MockAnnotation.new(description_annotation_key, description_annotation_value),
      MockAnnotation.new(upper_case_annotation_key, upper_case_annotation_value),
      MockAnnotation.new(invalid_gce_annotation_key, invalid_gce_annotation_value),
      MockAnnotation.new(empty_gce_key_annotation_key, empty_gce_key_annotation_value),
      MockAnnotation.new(empty_gce_val_annotation_key, empty_gce_val_annotation_value)
    ]
  }

  let(:annotations_list_with_duplications) {
    [
      MockAnnotation.new(gce_instance_name_annotation_key, gce_instance_name_annotation_value),
      MockAnnotation.new(description_annotation_key, description_annotation_value),
      MockAnnotation.new(gce_instance_name_annotation_key, gce_instance_name_annotation_value),
      MockAnnotation.new(description_annotation_key, description_annotation_value)
    ]
  }

  let(:expected_resource_restrictions_list_for_empty_prefix) {
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
        type: description_annotation_key,
        value: description_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: upper_case_annotation_key,
        value: upper_case_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: invalid_gce_annotation_key,
        value: invalid_gce_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: empty_gce_key_annotation_key,
        value: empty_gce_key_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: empty_gce_val_annotation_key,
        value: empty_gce_val_annotation_value
      )
    ]
  }

  let(:expected_resource_restrictions_list_for_valid_prefix) {
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
        type: empty_gce_key_annotation_key,
        value: empty_gce_key_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: empty_gce_val_annotation_key,
        value: empty_gce_val_annotation_value
      )
    ]
  }

  let(:expected_resource_restrictions_list_for_case_sensitive_prefix) {
    [
      Authentication::AuthnGce::ResourceRestriction.new(
        type: upper_case_annotation_key,
        value: upper_case_annotation_value
      )
    ]
  }

  let(:expected_resource_restrictions_list_for_without_slash_prefix) {
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
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: empty_gce_key_annotation_key,
        value: empty_gce_key_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: empty_gce_val_annotation_key,
        value: empty_gce_val_annotation_value
      )
    ]
  }

  let(:expected_resource_restrictions_list_with_duplications_for_empty_prefix) {
    [
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_instance_name_annotation_key,
        value: gce_instance_name_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: description_annotation_key,
        value: description_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_instance_name_annotation_key,
        value: gce_instance_name_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: description_annotation_key,
        value: description_annotation_value
      )
    ]
  }

  let(:expected_resource_restrictions_list_with_duplications_for_valid_prefix) {
    [
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_instance_name_annotation_key,
        value: gce_instance_name_annotation_value
      ),
      Authentication::AuthnGce::ResourceRestriction.new(
        type: gce_instance_name_annotation_key,
        value: gce_instance_name_annotation_value
      )
    ]
  }

  let(:mocked_resource_class_return_nil) {double("ResourceClassNil")}

  let(:mocked_resource_class_return_annotations_list) {double("ResourceClass")}
  let(:mocked_role_class_return_annotations_list) {double("RoleClass")}

  let(:mocked_resource_class_return_annotations_nil) {double("ResourceClass")}
  let(:mocked_role_class_return_annotations_nil) {double("RoleClass")}

  let(:mocked_resource_class_return_annotations_empty_list) {double("ResourceClass")}
  let(:mocked_role_class_return_annotations_empty_list) {double("RoleClass")}

  let(:mocked_resource_class_return_annotations_list_with_duplications) {double("ResourceClass")}
  let(:mocked_role_class_return_annotations_list_with_duplication) {double("RoleClass")}

  before(:each) do
    allow(mocked_resource_class_return_nil).to receive(:[])
                                                 .with(any_args)
                                                 .and_return(nil)


    allow(mocked_resource_class_return_annotations_list).to receive(:[])
                                                              .with(any_args)
                                                              .and_return(mocked_role_class_return_annotations_list)
    allow(mocked_role_class_return_annotations_list).to receive(:annotations)
                                                          .and_return(annotations_list)

    allow(mocked_resource_class_return_annotations_nil).to receive(:[])
                                                             .with(any_args)
                                                             .and_return(mocked_role_class_return_annotations_nil)
    allow(mocked_role_class_return_annotations_nil).to receive(:annotations)
                                                         .and_return(nil)

    allow(mocked_resource_class_return_annotations_empty_list).to receive(:[])
                                                                    .with(any_args)
                                                                    .and_return(mocked_role_class_return_annotations_empty_list)
    allow(mocked_role_class_return_annotations_empty_list).to receive(:annotations)
                                                                .and_return([])

    allow(mocked_resource_class_return_annotations_list_with_duplications).to receive(:[])
                                                                                .with(any_args)
                                                                                .and_return(mocked_role_class_return_annotations_list_with_duplication)
    allow(mocked_role_class_return_annotations_list_with_duplication).to receive(:annotations)
                                                                           .and_return(annotations_list_with_duplications)


  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "A valid resource restrictions configuration" do
    context "host contains multiple annotations" do
      context "when prefix is empty" do
        subject do
          Authentication::AuthnGce::ExtractResourceRestrictions.new(
            resource_class:          mocked_resource_class_return_annotations_list,
            validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
          ).call(
            account:           valid_account,
            username:          valid_host,
            extraction_prefix: empty_prefix
          )
        end

        it "returns expected list" do
          expect(subject).to eq(expected_resource_restrictions_list_for_empty_prefix)
        end
      end

      context "when prefix case-sensitive with value authn-GCE/" do
        subject do
          Authentication::AuthnGce::ExtractResourceRestrictions.new(
            resource_class:          mocked_resource_class_return_annotations_list,
            validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
          ).call(
            account:           valid_account,
            username:          valid_host,
            extraction_prefix: case_sensitive_prefix
          )
        end

        it "returns expected list" do
          expect(subject).to eq(expected_resource_restrictions_list_for_case_sensitive_prefix)
        end
      end

      context "when prefix without_slash_prefix" do
        subject do
          Authentication::AuthnGce::ExtractResourceRestrictions.new(
            resource_class:          mocked_resource_class_return_annotations_list,
            validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
          ).call(
            account:           valid_account,
            username:          valid_host,
            extraction_prefix: without_slash_prefix
          )
        end

        it "returns expected list" do
          expect(subject).to eq(expected_resource_restrictions_list_for_without_slash_prefix)
        end
      end

      context "when prefix is valid with value auth-gce/" do
        subject do
          Authentication::AuthnGce::ExtractResourceRestrictions.new(
            resource_class:          mocked_resource_class_return_annotations_list,
            validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
          ).call(
            account:           valid_account,
            username:          valid_host,
            extraction_prefix: valid_prefix
          )
        end

        it "returns expected list" do
          expect(subject).to eq(expected_resource_restrictions_list_for_valid_prefix)
        end
      end
    end

    context "host not contains annotations" do
      context "when annotations returned is empty list" do
        subject do
          Authentication::AuthnGce::ExtractResourceRestrictions.new(
            resource_class:          mocked_resource_class_return_annotations_empty_list,
            validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
          ).call(
            account:           valid_account,
            username:          valid_host,
            extraction_prefix: valid_prefix
          )
        end

        it "returns expected list" do
          expect(subject).to eq([])
        end
      end
    end

    context "host contains duplicate annotations" do
      context "when prefix is empty" do
        subject do
          Authentication::AuthnGce::ExtractResourceRestrictions.new(
            resource_class:          mocked_resource_class_return_annotations_list_with_duplications,
            validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
          ).call(
            account:           valid_account,
            username:          valid_host,
            extraction_prefix: empty_prefix
          )
        end

        it "returns expected list" do
          expect(subject).to eq(expected_resource_restrictions_list_with_duplications_for_empty_prefix)
        end
      end

      context "when prefix is valid with value auth-gce/" do
        subject do
          Authentication::AuthnGce::ExtractResourceRestrictions.new(
            resource_class:          mocked_resource_class_return_annotations_list_with_duplications,
            validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
          ).call(
            account:           valid_account,
            username:          valid_host,
            extraction_prefix: valid_prefix
          )
        end

        it "returns expected list" do
          expect(subject).to eq(expected_resource_restrictions_list_with_duplications_for_valid_prefix)
        end
      end
    end
  end

  context "An invalid input parameters to extract resource restrictions" do
    context "when account does not exists" do
      subject do
        Authentication::AuthnGce::ExtractResourceRestrictions.new(
          resource_class:          mocked_resource_class_return_nil,
          validate_account_exists: mock_validate_account_exists(validation_succeeded: false)
        ).call(
          account:           invalid_account,
          username:          valid_host,
          extraction_prefix: valid_prefix
        )
      end

      it "raises an error" do
        expect {subject}.to raise_error(validate_account_exists_error)
      end

      context "when host does not exists" do
        subject do
          Authentication::AuthnGce::ExtractResourceRestrictions.new(
            resource_class:          mocked_resource_class_return_nil,
            validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
          ).call(
            account:           valid_account,
            username:          invalid_host,
            extraction_prefix: valid_prefix
          )
        end

        it "raises an error" do
          expect {subject}.to raise_error(Errors::Authentication::Security::RoleNotFound)
        end
      end
    end
  end
end
