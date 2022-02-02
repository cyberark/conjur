# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthHostDetails) do
  let(:id) { "host-id" }
  let(:json_hash) { { "id" => id, "annotations" => annotations } }
  let(:json_hash_no_annotations) { { "id" => id } }

  subject(:host_details) do
    Authentication::AuthHostDetails.new(
      json_hash, constraints: constraints
    )
  end

  subject(:host_details_no_annotations) do
    Authentication::AuthHostDetails.new(
      json_hash_no_annotations, constraints: constraints
    )
  end

  context "We initialize an AuthHostDetails object with no constraints" do
    let(:constraints) { nil }

    it("should be a valid object") do
      expect(host_details_no_annotations).to receive(:validate_annotations).and_return(nil)
      expect(host_details_no_annotations.valid?).to eq(true)
    end
  end

  context "We initialize an AuthHostDetails object with constraints" do
    let(:constraints) { double('Constraints') }

    context "With no annotations" do
      it("should not validate using the constraints object") do
        expect(host_details_no_annotations).to receive(:validate_annotations).and_return(nil)
        expect(constraints).not_to receive(:validate)

        expect(host_details_no_annotations.valid?).to eq(true)
      end
    end

    context "With only non-authenticator annotations" do
      let(:annotations) { {"first" => "value", "second" => "value"} }

      it("Should pass an empty list to the validate function") do
        expect(constraints).to receive(:validate).with({resource_restrictions: []})
        expect(host_details.annotations).to eq(annotations)

        expect(host_details.valid?).to eq(true)
      end
    end

    context "With one authenticator annotation" do
      let(:annotations) { {"first" => "value", "second" => "value", "authn-k8s/namespace" => "test"} }

      it("Should pass the annotation name to the validate function") do
        expect(constraints).to receive(:validate).with({resource_restrictions: ["namespace"]})
        expect(host_details.annotations).to eq(annotations)

        expect(host_details.valid?).to eq(true)
      end
    end

    context "With multiple authenticator annotations" do
      let(:annotations) {
        {
          "first" => "value",
          "second" => "value",
          "authn-k8s/namespace" => "test",
          "authn-k8s/other" => "second_annotation"
        }
      }

      it("Should pass the annotation names to the validate function") do
        expect(constraints).to receive(:validate).with({resource_restrictions: ["namespace", "other"]})
        expect(host_details.annotations).to eq(annotations)

        expect(host_details.valid?).to eq(true)
      end

      context "With invalid authenticator annotations" do
        let(:error_message) { "this is the error message" }

        it("Should add the correct error if annotations don't fit constraints") do
          allow(constraints).to receive(:validate)
            .with({resource_restrictions: ["namespace", "other"]})
            .and_raise(error_message)

          expect(host_details.valid?).to eq(false)
          expect(host_details.errors[:annotations]).to eq([error_message])
        end
      end
    end
  end

end
