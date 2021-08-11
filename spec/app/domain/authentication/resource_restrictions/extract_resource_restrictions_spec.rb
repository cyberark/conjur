# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::ResourceRestrictions::ExtractResourceRestrictions) do
  let(:authenticator_name) { 'authn-name' }
  let(:service_id) { 'service-id' }
  let(:role_name) { 'role-name' }
  let(:account) { 'account' }

  let(:mocked_fetch_resource_annotations_instance_invalid) { double("FetchResourceAnnotationsInvalid") }
  let(:fetch_resource_annotations_instance_error) { "FetchResourceAnnotationsError" }
  let(:mocked_fetch_resource_annotations_instance_empty) { double("FetchResourceAnnotationsEmpty") }
  let(:mocked_fetch_resource_annotations_instance_valid) { double("FetchResourceAnnotationsValid") }


  let(:resource_restrictions_empty_hash) {
    Authentication::ResourceRestrictions::ResourceRestrictions.new(
      resource_restrictions_hash: {}
    )
  }

  before(:each) do
    allow(mocked_fetch_resource_annotations_instance_invalid).to(
      receive(:call).and_raise(fetch_resource_annotations_instance_error)
    )

    allow(mocked_fetch_resource_annotations_instance_empty).to(
      receive(:call).and_return({})
    )

    allow(mocked_fetch_resource_annotations_instance_valid).to(
      receive(:call).and_return(
        "#{authenticator_name}/#{service_id}/claim1" => "claim1-value",
        "#{authenticator_name}/#{service_id}/claim2" => "claim2-value"
      )
    )
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "Failed to extract resource restrictions" do
    context "When was an error in fetch resource annotations" do
      subject do
        Authentication::ResourceRestrictions::ExtractResourceRestrictions.new(
          fetch_resource_annotations_instance: mocked_fetch_resource_annotations_instance_invalid
        ).call(
          authenticator_name: authenticator_name,
          service_id: authenticator_name,
          role_name: role_name,
          account: account
        )
      end

      it "returns an error" do
        expect{ subject }.to raise_error(fetch_resource_annotations_instance_error)
      end
    end
  end

  context "Successfully extract resource restrictions" do
    context "When fetch resource annotations returns an empty hash" do
      subject do
        Authentication::ResourceRestrictions::ExtractResourceRestrictions.new(
          fetch_resource_annotations_instance: mocked_fetch_resource_annotations_instance_empty
        ).call(
          authenticator_name: authenticator_name,
          service_id: authenticator_name,
          role_name: role_name,
          account: account
        )
      end

      it "returns resource restrictions with empty hash" do
        expect(subject.any?).to eql(false)
      end
    end

    context "When fetch resource annotations returns a valid hash" do
      subject do
        Authentication::ResourceRestrictions::ExtractResourceRestrictions.new(
          fetch_resource_annotations_instance: mocked_fetch_resource_annotations_instance_valid
        ).call(
          authenticator_name: authenticator_name,
          service_id: service_id,
          role_name: role_name,
          account: account
        )
      end

      it "returns resource restrictions object with 2 claims" do
        expect(subject.names).to eql(%w[claim1 claim2])
      end
    end
  end
end
