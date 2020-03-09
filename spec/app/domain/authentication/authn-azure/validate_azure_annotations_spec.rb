# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::AuthnAzure::ValidateAzureAnnotations' do

  let(:good_service_id) { "MockServiceId" }

  let(:subscription_id_annotation) { double("SubscriptionIdAnnotation") }

  let(:subscription_id_annotation_service_id_scoped) { double("SubscriptionIdServiceIdAnnotation") }

  let(:resource_group_annotation) { double("ResourceGroupAnnotation") }

  let(:resource_group_annotation_service_id_scoped) { double("ResourceGroupServiceIdAnnotation") }

  let(:invalid_azure_annotation) { double("InvalidAzureAnnotation") }

  let(:non_azure_annotation) { double("NonAzureAnnotation") }

  let(:invalid_azure_annotation_service_id_scoped) { double("InvalidAzureAnnotationServiceIdScoped") }

  before(:each) do
    allow(subscription_id_annotation).to receive(:values)
                                           .and_return(subscription_id_annotation)
    allow(subscription_id_annotation).to receive(:[])
                                           .with(:name)
                                           .and_return("authn-azure/subscription-id")
    allow(subscription_id_annotation).to receive(:[])
                                           .with(:value)
                                           .and_return("some-subscription-id-value")

    allow(subscription_id_annotation_service_id_scoped).to receive(:values)
                                                             .and_return(subscription_id_annotation_service_id_scoped)
    allow(subscription_id_annotation_service_id_scoped).to receive(:[])
                                                             .with(:name)
                                                             .and_return("authn-azure/#{good_service_id}/subscription-id")
    allow(subscription_id_annotation_service_id_scoped).to receive(:[])
                                                             .with(:value)
                                                             .and_return("AzureSubscriptionIdServiceIdScoped")

    allow(resource_group_annotation).to receive(:values)
                                          .and_return(resource_group_annotation)
    allow(resource_group_annotation).to receive(:[])
                                          .with(:name)
                                          .and_return("authn-azure/resource-group")
    allow(resource_group_annotation).to receive(:[])
                                          .with(:value)
                                          .and_return("some-resource-group-value")

    allow(resource_group_annotation_service_id_scoped).to receive(:values)
                                                            .and_return(resource_group_annotation_service_id_scoped)
    allow(resource_group_annotation_service_id_scoped).to receive(:[])
                                                            .with(:name)
                                                            .and_return("authn-azure/#{good_service_id}/resource-group")
    allow(resource_group_annotation_service_id_scoped).to receive(:[])
                                                            .with(:value)
                                                            .and_return("AzureResourceGroupServiceIdScoped")

    allow(invalid_azure_annotation).to receive(:values)
                                   .and_return(invalid_azure_annotation)
    allow(invalid_azure_annotation).to receive(:[])
                                   .with(:name)
                                   .and_return("authn-azure/non_existing")

    allow(non_azure_annotation).to receive(:values)
                                   .and_return(non_azure_annotation)
    allow(non_azure_annotation).to receive(:[])
                                   .with(:name)
                                   .and_return("authn-test/non_existing")

    allow(invalid_azure_annotation_service_id_scoped).to receive(:values)
                                     .and_return(invalid_azure_annotation_service_id_scoped)
    allow(invalid_azure_annotation_service_id_scoped).to receive(:[])
                                                             .with(:name)
                                                             .and_return("authn-azure/#{good_service_id}/non-existing")
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
            service_id: good_service_id
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
            service_id: good_service_id
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
            role_annotations: [subscription_id_annotation_service_id_scoped, resource_group_annotation_service_id_scoped],
            service_id: good_service_id
          )
        end

        it "does not raise an error" do
          expect { subject }.to_not raise_error
        end
      end

      context "that are not permitted" do
        subject do
          Authentication::AuthnAzure::ValidateAzureAnnotations.new.call(
            role_annotations: [subscription_id_annotation_service_id_scoped, invalid_azure_annotation_service_id_scoped],
            service_id: good_service_id
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
          service_id: good_service_id
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
          service_id: good_service_id
        )
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end
  end
end
