# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::AuthnAzure::ApplicationIdentity do
  let(:subscription_id_annotation) { double("SubscriptionIdAnnotation") }
  let(:subscription_id_annotation_empty) {double("SubscriptionIdAnnotationEmpty") }
  let(:subscription_id_service_id_scoped_annotation) { double("SubscriptionIdServiceIdAnnotation") }

  let(:good_service_id) { "MockService" }

  let(:global_annotation_type) { "authn-azure" }
  let(:granular_annotation_type) { "authn-azure/#{good_service_id}" }

  def mock_annotation_builder(host_annotation_type, host_annotation_key, host_annotation_value)
    allow(host_annotation_type).to receive(:values)
                                     .and_return(host_annotation_type)
    allow(host_annotation_type).to receive(:[])
                                     .with(:name)
                                     .and_return(host_annotation_key)
    allow(host_annotation_type).to receive(:[])
                                     .with(:value)
                                     .and_return(host_annotation_value)
  end

  before(:each) do
    mock_annotation_builder(subscription_id_annotation, "#{global_annotation_type}/subscription-id", "some-subscription-id-value")
    mock_annotation_builder(subscription_id_annotation_empty, "#{global_annotation_type}/subscription-id", "")
    mock_annotation_builder(subscription_id_service_id_scoped_annotation, "#{granular_annotation_type}/subscription-id", "some-subscription-id-service-id-scoped-value")
  end

  context "initialization" do
    subject(:application_identity) {
      Authentication::AuthnAzure::ApplicationIdentity.new(
        role_annotations: role_annotations,
        service_id:       good_service_id
      )
    }
    context("An application identity in annotations") do
      context("with a global scoped constraint") do
        let(:role_annotations) { [subscription_id_annotation] }

        it "Returns Hash of the constraint and its value" do
          expect(subject.constraints).to eq({ subscription_id: "some-subscription-id-value" })
        end
      end

      context("with a service-id scoped constraint") do
        let(:role_annotations) { [subscription_id_service_id_scoped_annotation] }

        it "Returns Hash of the constraint and its value" do
          expect(subject.constraints).to eq({ subscription_id: "some-subscription-id-service-id-scoped-value" })
        end
      end

      context("with both global & service-id scoped constraints") do
        let(:role_annotations) { [subscription_id_annotation, subscription_id_service_id_scoped_annotation] }

        it ("chooses the service-id scoped constraint") do
          expect(subject.constraints).to eq({ subscription_id: "some-subscription-id-service-id-scoped-value" })
        end
      end

      context("with an empty annotation value") do
        let(:role_annotations) { [subscription_id_annotation_empty] }

        it "Returns Hash of the constraint and an empty value" do
          expect(subject.constraints).to eq({ subscription_id: "" })
        end
      end
    end
  end
end