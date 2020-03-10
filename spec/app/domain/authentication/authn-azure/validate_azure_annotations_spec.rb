# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::AuthnAzure::ValidateAzureAnnotations' do
  include_context "azure setup"

  let(:test_service_id) { "MockServiceId" }

  let(:subscription_id_service_id_scoped_annotation) { double("SubscriptionIdServiceIdAnnotation") }
  let(:resource_group_service_id_scoped_annotation) { double("ResourceGroupServiceIdAnnotation") }

  let(:invalid_azure_annotation) { double("InvalidAzureAnnotation") }
  let(:non_azure_annotation) { double("NonAzureAnnotation") }
  let(:invalid_azure_annotation_service_id_scoped) { double("InvalidAzureAnnotationServiceIdScoped") }

  let(:global_annotation_type) { "authn-azure" }
  let(:granular_annotation_type) { "authn-azure/#{test_service_id}" }


  before(:each) do
    define_host_annotation(subscription_id_service_id_scoped_annotation, "#{granular_annotation_type}/subscription-id", "some-subscription-id-service-id-scoped-value")
    define_host_annotation(resource_group_service_id_scoped_annotation, "#{granular_annotation_type}/resource-group", "some-resource-group-service-id-scoped-value")

    define_host_annotation(invalid_azure_annotation, "#{global_annotation_type}/non_existing", "some-azure-non-existing-value")
    define_host_annotation(invalid_azure_annotation_service_id_scoped, "#{granular_annotation_type}/non-existing", "some-invalid-existing-value")
    define_host_annotation(non_azure_annotation, "authn-test/non_existing", "some-non-existing-value")
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
