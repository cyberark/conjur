# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::AuthnAzure::ValidateAzureAnnotations' do
  include_context "azure setup"

  let(:invalid_azure_annotation) { double("InvalidAzureAnnotation") }
  let(:invalid_azure_annotation_service_id_scoped) { double("InvalidAzureAnnotationServiceIdScoped") }

  before(:each) do
    define_host_annotation(host_annotation_type:  invalid_azure_annotation,
                           host_annotation_key:   "#{global_annotation_type}/non_existing",
                           host_annotation_value: "some-azure-non-existing-value")
    define_host_annotation(host_annotation_type:  invalid_azure_annotation_service_id_scoped,
                           host_annotation_key:   "#{granular_annotation_type}/non-existing",
                           host_annotation_value: "some-invalid-existing-value")
    define_host_annotation(host_annotation_type:  non_azure_annotation,
                           host_annotation_key:   "authn-test/non_existing",
                           host_annotation_value: "some-non-existing-value")
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "A list of annotations" do
    context "that contains Azure globally-scoped annotations" do
      context "that are all permitted" do
        subject do
          Authentication::AuthnAzure::ValidateAzureAnnotations.new.call(
            role_annotations: [subscription_id_annotation, resource_group_annotation],
            service_id:       test_service_id
          )
        end

        it "does not raise an error" do
          expect { subject }.to_not raise_error
        end
      end

      context "that are not permitted" do
        subject do
          Authentication::AuthnAzure::ValidateAzureAnnotations.new.call(
            role_annotations: [subscription_id_annotation, invalid_azure_annotation],
            service_id:       test_service_id
          )
        end

        it "raises a ConstraintNotSupported error" do
          expect { subject }.to raise_error(::Errors::Authentication::AuthnAzure::ConstraintNotSupported)
        end
      end
    end

    context "that contains Azure service-id scoped annotations" do
      context "that are all permitted" do
        subject do
          Authentication::AuthnAzure::ValidateAzureAnnotations.new.call(
            role_annotations: [subscription_id_service_id_scoped_annotation, resource_group_service_id_scoped_annotation],
            service_id:       test_service_id
          )
        end

        it "does not raise an error" do
          expect { subject }.to_not raise_error
        end
      end

      context "that are not permitted" do
        subject do
          Authentication::AuthnAzure::ValidateAzureAnnotations.new.call(
            role_annotations: [subscription_id_service_id_scoped_annotation, invalid_azure_annotation_service_id_scoped],
            service_id:       test_service_id
          )
        end

        it "raises a ConstraintNotSupported error" do
          expect { subject }.to raise_error(::Errors::Authentication::AuthnAzure::ConstraintNotSupported)
        end
      end
    end

    context "that does not contain Azure-specific annotations" do
      subject do
        Authentication::AuthnAzure::ValidateAzureAnnotations.new.call(
          role_annotations: [non_azure_annotation],
          service_id:       test_service_id
        )
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end

    context "that is empty" do
      subject do
        Authentication::AuthnAzure::ValidateAzureAnnotations.new.call(
          role_annotations: [],
          service_id:       test_service_id
        )
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end
  end
end
