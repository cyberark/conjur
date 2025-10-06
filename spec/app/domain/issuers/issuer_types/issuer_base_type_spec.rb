# frozen_string_literal: true

require 'spec_helper'

describe Issuers::IssuerTypes::IssuerBaseType do
  subject { Issuers::IssuerTypes::IssuerBaseType.new }

  let(:id) { 'aws_issuer-1' }
  let(:max_ttl) { 2000 }
  let(:type) { 'aws' }
  let(:data) { {} }

  describe '#validate' do
    let(:params) do
      ActionController::Parameters.new(
        id: id,
        max_ttl: max_ttl,
        type: type,
        data: data
      )
    end

    context "when all base input is valid" do
      it "successfully validates" do
        expect { subject.validate(params) }.to_not raise_error
      end
    end

    shared_examples_for 'fails input validation' do
      it 'fails input validation' do
        expect { subject.validate(params) }
          .to raise_error(ApplicationController::BadRequestWithBody)
      end
    end

    context "when max_ttl is nil" do
      let(:max_ttl) { nil }
      include_examples 'fails input validation'
    end

    context "when max_ttl is a negative number" do
      let(:max_ttl) { -2000 }
      include_examples 'fails input validation'
    end

    context "when max_ttl is out of lower bounds" do
      let(:max_ttl) { 899 }
      include_examples 'fails input validation'
    end

    context "when max_ttl is out of upper bounds" do
      let(:max_ttl) { 43201 }
      include_examples 'fails input validation'
    end

    context "when max_ttl is 0" do
      let(:max_ttl) { 0 }
      include_examples 'fails input validation'
    end

    context "when max_ttl is a floating number" do
      let(:max_ttl) { 4.5 }
      include_examples 'fails input validation'
    end

    context "when id is a nil" do
      let(:id) { nil }
      include_examples 'fails input validation'
    end

    context "when id is empty" do
      let(:id) { "" }
      include_examples 'fails input validation'
    end

    context "when id is a number" do
      let(:id) { 1 }
      include_examples 'fails input validation'
    end

    context "when id is longer than 60 characters" do
      let(:id) { "a" * 61 }
      include_examples 'fails input validation'
    end

    context "when id has invalid character ^" do
      let(:id) { "a^" }
      include_examples 'fails input validation'
    end

    context "when id has invalid character of a space" do
      let(:id) { "a hf" }
      include_examples 'fails input validation'
    end

    context "when type is nil" do
      let(:type) { nil }
      include_examples 'fails input validation'
    end

    context "when type is empty" do
      let(:type) { "" }
      include_examples 'fails input validation'
    end

    context "when type is not a string" do
      let(:type) { 1 }
      include_examples 'fails input validation'
    end

    context "when data is nil" do
      let(:data) { nil }
      include_examples 'fails input validation'
    end

    context "when invalid parameter is added to the body main section" do
      let(:params) do
        ActionController::Parameters.new(
          id: id,
          max_ttl: max_ttl,
          type: type,
          invalid_param: "a",
          data: data
        )
      end

      include_examples 'fails input validation'
    end
  end

  describe '#validate_update' do
    context 'when only max_ttl and data fields are present and valid' do
      let(:params) do
        ActionController::Parameters.new(
          max_ttl: max_ttl,
          data: data
        )
      end

      it 'passes validation' do
        expect { subject.validate_update(params) }.to_not raise_error
      end
    end

    context 'when extra parameters are passed' do
      let(:params) do
        ActionController::Parameters.new(
          max_ttl: max_ttl,
          data: data,
          extra: "test"
        )
      end

      it 'fails validation' do
        expect { subject.validate_update(params) }
          .to raise_error ApplicationController::BadRequestWithBody
      end
    end

    context "when max_ttl isn't specified" do
      let(:params) do
        ActionController::Parameters.new(
          data: data
        )
      end

      it "successfully validates" do
        expect { subject.validate_update(params) }.to_not raise_error
      end
    end
  end
end
