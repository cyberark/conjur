# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::AuthnGcp::ExtractResourceRestrictions' do

  include_context "security mocks"

  let(:valid_account) {'valid-account'}
  let(:invalid_account) {'invalid-account'}

  let(:valid_host) {'valid-host'}
  let(:invalid_host) {'invalid-host'}

  let(:valid_prefix) {'authn-gcp/'}
  let(:empty_prefix) {''}
  let(:case_sensitive_prefix) {'authn-GCP/'}
  let(:without_slash_prefix) {'authn-gcp'}

  let(:gcp_instance_name_annotation_key) {'authn-gcp/instance-name'}
  let(:gcp_instance_name_annotation_value) {'instance-name'}
  let(:gcp_project_id_annotation_key) {'authn-gcp/project-id'}
  let(:gcp_project_id_annotation_value) {'project-id'}
  let(:gcp_service_account_id_annotation_key) {'authn-gcp/service-account-id'}
  let(:gcp_service_account_id_annotation_value) {'service account id'}
  let(:gcp_service_account_email_annotation_key) {'authn-gcp/service-account-email'}
  let(:gcp_service_account_email_annotation_value) {'service_account_email'}
  let(:description_annotation_key) {'description'}
  let(:description_annotation_value) {'this is the best gcp host in Conjur'}
  let(:upper_case_annotation_key) {'authn-GCP/'}
  let(:upper_case_annotation_value) {'not authn-gcp/'}
  let(:invalid_gcp_annotation_key) {'authn-gcp'}
  let(:invalid_gcp_annotation_value) {'not authn-gcp/'}
  let(:empty_gcp_key_annotation_key) {'authn-gcp/'}
  let(:empty_gcp_key_annotation_value) {'empty key prefix'}
  let(:empty_gcp_val_annotation_key) {'authn-gcp/empty-val'}
  let(:empty_gcp_val_annotation_value) {''}

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
      MockAnnotation.new(gcp_instance_name_annotation_key, gcp_instance_name_annotation_value),
      MockAnnotation.new(gcp_project_id_annotation_key, gcp_project_id_annotation_value),
      MockAnnotation.new(gcp_service_account_id_annotation_key, gcp_service_account_id_annotation_value),
      MockAnnotation.new(gcp_service_account_email_annotation_key, gcp_service_account_email_annotation_value),
      MockAnnotation.new(description_annotation_key, description_annotation_value),
      MockAnnotation.new(upper_case_annotation_key, upper_case_annotation_value),
      MockAnnotation.new(invalid_gcp_annotation_key, invalid_gcp_annotation_value),
      MockAnnotation.new(empty_gcp_key_annotation_key, empty_gcp_key_annotation_value),
      MockAnnotation.new(empty_gcp_val_annotation_key, empty_gcp_val_annotation_value)
    ]
  }

  let(:annotations_list_with_duplications) {
    [
      MockAnnotation.new(gcp_instance_name_annotation_key, gcp_instance_name_annotation_value),
      MockAnnotation.new(description_annotation_key, description_annotation_value),
      MockAnnotation.new(gcp_instance_name_annotation_key, gcp_instance_name_annotation_value),
      MockAnnotation.new(description_annotation_key, description_annotation_value)
    ]
  }

  let(:expected_resource_restrictions_list_for_empty_prefix) {
    [
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: gcp_instance_name_annotation_key,
        value: gcp_instance_name_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: gcp_project_id_annotation_key,
        value: gcp_project_id_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: gcp_service_account_id_annotation_key,
        value: gcp_service_account_id_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: gcp_service_account_email_annotation_key,
        value: gcp_service_account_email_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: description_annotation_key,
        value: description_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: upper_case_annotation_key,
        value: upper_case_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: invalid_gcp_annotation_key,
        value: invalid_gcp_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: empty_gcp_key_annotation_key,
        value: empty_gcp_key_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: empty_gcp_val_annotation_key,
        value: empty_gcp_val_annotation_value
      )
    ]
  }

  let(:expected_resource_restrictions_list_for_valid_prefix) {
    [
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: gcp_instance_name_annotation_key,
        value: gcp_instance_name_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: gcp_project_id_annotation_key,
        value: gcp_project_id_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: gcp_service_account_id_annotation_key,
        value: gcp_service_account_id_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: gcp_service_account_email_annotation_key,
        value: gcp_service_account_email_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: empty_gcp_key_annotation_key,
        value: empty_gcp_key_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: empty_gcp_val_annotation_key,
        value: empty_gcp_val_annotation_value
      )
    ]
  }

  let(:expected_resource_restrictions_list_for_case_sensitive_prefix) {
    [
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: upper_case_annotation_key,
        value: upper_case_annotation_value
      )
    ]
  }

  let(:expected_resource_restrictions_list_for_without_slash_prefix) {
    [
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: gcp_instance_name_annotation_key,
        value: gcp_instance_name_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: gcp_project_id_annotation_key,
        value: gcp_project_id_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: gcp_service_account_id_annotation_key,
        value: gcp_service_account_id_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: gcp_service_account_email_annotation_key,
        value: gcp_service_account_email_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: invalid_gcp_annotation_key,
        value: invalid_gcp_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: empty_gcp_key_annotation_key,
        value: empty_gcp_key_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: empty_gcp_val_annotation_key,
        value: empty_gcp_val_annotation_value
      )
    ]
  }

  let(:expected_resource_restrictions_list_with_duplications_for_empty_prefix) {
    [
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: gcp_instance_name_annotation_key,
        value: gcp_instance_name_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: description_annotation_key,
        value: description_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: gcp_instance_name_annotation_key,
        value: gcp_instance_name_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: description_annotation_key,
        value: description_annotation_value
      )
    ]
  }

  let(:expected_resource_restrictions_list_with_duplications_for_valid_prefix) {
    [
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: gcp_instance_name_annotation_key,
        value: gcp_instance_name_annotation_value
      ),
      Authentication::AuthnGcp::ResourceRestriction.new(
        type: gcp_instance_name_annotation_key,
        value: gcp_instance_name_annotation_value
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
          Authentication::AuthnGcp::ExtractResourceRestrictions.new(
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

      context "when prefix case-sensitive with value authn-GCP/" do
        subject do
          Authentication::AuthnGcp::ExtractResourceRestrictions.new(
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
          Authentication::AuthnGcp::ExtractResourceRestrictions.new(
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

      context "when prefix is valid with value auth-gcp/" do
        subject do
          Authentication::AuthnGcp::ExtractResourceRestrictions.new(
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
      context "when annotations returned is nil" do
        subject do
          Authentication::AuthnGcp::ExtractResourceRestrictions.new(
            resource_class:          mocked_resource_class_return_annotations_nil,
            validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
          ).call(
            account:           valid_account,
            username:          valid_host,
            extraction_prefix: valid_prefix
          )
        end

        it "raises an error" do
          expect {subject}.to raise_error(Errors::Conjur::FetchAnnotationsFailed)
        end
      end

      context "when annotations returned is empty list" do
        subject do
          Authentication::AuthnGcp::ExtractResourceRestrictions.new(
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
          Authentication::AuthnGcp::ExtractResourceRestrictions.new(
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

      context "when prefix is valid with value auth-gcp/" do
        subject do
          Authentication::AuthnGcp::ExtractResourceRestrictions.new(
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
        Authentication::AuthnGcp::ExtractResourceRestrictions.new(
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
          Authentication::AuthnGcp::ExtractResourceRestrictions.new(
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
