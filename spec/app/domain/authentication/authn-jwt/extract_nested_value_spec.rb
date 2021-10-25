# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnJwt::ExtractNestedValue) do

  let(:dictionary) {
    {
      "first" => "value_1",
      "second" =>
        {
          "key_2" => "value_2"
        },
      "third" =>
        {
          "obj" =>
            {
              "key_3" => "value_3"
            }
        }
    }
  }

  context "Fetching existing key" do
    context "From the first level" do
      subject do
        Authentication::AuthnJwt::ExtractNestedValue.new.call(
          hash_map: dictionary,
          path: "first"
        )
      end

      it "returns a valid value" do
        expect(subject).to eq("value_1")
      end
    end

    context "From the second level" do
      subject do
        Authentication::AuthnJwt::ExtractNestedValue.new.call(
          hash_map: dictionary,
          path: "second/key_2"
        )
      end

      it "returns a valid value" do
        expect(subject).to eq("value_2")
      end
    end

    context "From the third level" do
      subject do
        Authentication::AuthnJwt::ExtractNestedValue.new.call(
          hash_map: dictionary,
          path: "third/obj/key_3"
        )
      end

      it "returns a valid value" do
        expect(subject).to eq("value_3")
      end
    end

    context "From the third level with non default separator" do
      subject do
        Authentication::AuthnJwt::ExtractNestedValue.new.call(
          hash_map: dictionary,
          path: "third-obj-key_3",
          path_separator: '-'
        )
      end

      it "returns a valid value" do
        expect(subject).to eq("value_3")
      end
    end
  end

  context "Fetching absent key" do
    context "From the first level" do
      subject do
        Authentication::AuthnJwt::ExtractNestedValue.new.call(
          hash_map: dictionary,
          path: "absent"
        )
      end

      it "returns nil" do
        expect(subject).to eq(nil)
      end
    end

    context "From the second level" do
      subject do
        Authentication::AuthnJwt::ExtractNestedValue.new.call(
          hash_map: dictionary,
          path: "second/absent"
        )
      end

      it "returns nil" do
        expect(subject).to eq(nil)
      end
    end
  end
end
