# frozen_string_literal: true

require 'spec_helper'

describe Issuers::IssuerTypes::AwsIssuerType do
  subject { Issuers::IssuerTypes::AwsIssuerType.new }

  let(:params) do
    ActionController::Parameters.new(
      id: id,
      max_ttl: max_ttl,
      type: type,
      data: data
    )
  end

  let(:id) { "aws-issuer-1" }
  let(:max_ttl) { 2000 }
  let(:type) { "aws" }
  let(:data) do
    {
      access_key_id: access_key_id,
      secret_access_key: secret_access_key
    }
  end
  let(:access_key_id) { "AKIAIOSFODNN7EXAMPLE" }
  let(:secret_access_key) { "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" }

  describe '#validate' do
    context "when all input is valid" do
      it "does not raise a validation error" do
        expect { subject.validate(params) }
          .to_not raise_error
      end
    end

    shared_examples_for 'fails input validation' do |error_class|
      it 'fails input validation' do
        expect { subject.validate(params) }
          .to raise_error(error_class)
      end
    end

    context "when data is not given" do
      let(:params) do
        ActionController::Parameters.new(
          id: id,
          max_ttl: max_ttl,
          type: type
        )
      end
      include_examples 'fails input validation',
                       ApplicationController::BadRequestWithBody
    end

    context "when data is the wrong type" do
      let(:params) do
        ActionController::Parameters.new(
          id: id,
          max_ttl: max_ttl,
          type: type,
          data: "test"
        )
      end
      include_examples 'fails input validation',
                       ApplicationController::BadRequestWithBody
    end

    context "when key id is not given in the data field" do
      let(:data) do
        {
          secret_access_key: "a"
        }
      end
      include_examples 'fails input validation',
                       ApplicationController::UnprocessableEntity
    end

    context "when secret access key is not given in the data field" do
      let(:data) do
        {
          access_key_id: "a"
        }
      end
      include_examples 'fails input validation',
                       ApplicationController::UnprocessableEntity
    end

    context "when secret access key is nil" do
      let(:data) do
        {
          access_key_id: nil
        }
      end
      include_examples 'fails input validation',
                       ApplicationController::UnprocessableEntity
    end

    context "when key id is not a string" do
      let(:access_key_id) { 1 }
      include_examples 'fails input validation',
                       ApplicationController::UnprocessableEntity
    end

    context "when key id is an empty string" do
      let(:access_key_id) { "" }
      include_examples 'fails input validation',
                       ApplicationController::UnprocessableEntity
    end

    context "when secret access key is not a string" do
      let(:secret_access_key) { 1 }
      include_examples 'fails input validation',
                       ApplicationController::UnprocessableEntity
    end

    context "when secret access key is an empty string" do
      let(:secret_access_key) { "" }
      include_examples 'fails input validation',
                       ApplicationController::UnprocessableEntity
    end

    context "when invalid parameter is added to the data" do
      let(:data) do
        {
          access_key_id: access_key_id,
          secret_access_key: secret_access_key,
          invalid_param: "a"
        }
      end
      include_examples 'fails input validation',
                       ApplicationController::UnprocessableEntity
    end

    context "when access key id is not in the correct format" do
      let(:access_key_id) { "a" }
      include_examples 'fails input validation',
                       ApplicationController::UnprocessableEntity
    end

    context "when secret access key is not in the correct format" do
      let(:secret_access_key) { "a" }
      include_examples 'fails input validation',
                       ApplicationController::UnprocessableEntity
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
        expect { subject.validate_update(params) }
          .to_not raise_error
      end
    end

    context 'when data is not included' do
      let(:params) do
        ActionController::Parameters.new(
          max_ttl: max_ttl,
        )
      end

      it 'validates successfully' do
        expect { subject.validate_update(params) }
          .to_not raise_error
      end
    end
  end

  describe '#validate_variable' do
    let(:variable_id) { 'data/dynamic/test' }
    let(:variable_method) { 'assume-role' }
    let(:variable_ttl) { 2000 }
    let(:issuer) do
      Issuer.new(
        issuer_id: id,
        max_ttl: max_ttl,
        issuer_type: type,
        data: data.to_json
      )
    end

    def validate_variable
      subject.validate_variable(
        variable_id,
        variable_method,
        variable_ttl,
        issuer
      )
    end

    shared_examples_for 'fails variable validation' do |error_class|
      it 'fails input validation' do
        expect { validate_variable }.to raise_error(error_class)
      end
    end

    context 'when ttl is absent' do
      let(:variable_ttl) { nil }

      it 'validates successfully' do
        expect { validate_variable }.to_not raise_error
      end
    end

    context 'when ttl exceeds issuer max' do
      let(:variable_ttl) { max_ttl + 1 }
      include_examples 'fails variable validation', ArgumentError
    end


    context 'when method is assume-role' do
      context 'when the ttl is valid' do
        let(:variable_ttl) { 2000 }
        it 'validates successfully' do
          expect { validate_variable }.to_not raise_error
        end
      end

      context 'when the ttl is too high' do
        let(:variable_ttl) { 129601 }
        include_examples 'fails variable validation', ArgumentError
      end

      context 'when the ttl is too low' do
        let(:variable_ttl) { 899 }
        include_examples 'fails variable validation', ArgumentError
      end
    end

    context 'when method is federation-token' do
      let(:variable_method) { 'federation-token' }

      context 'when the ttl is valid' do
        let(:variable_ttl) { 2000 }
        it 'validates successfully' do
          expect { validate_variable }.to_not raise_error
        end
      end

      context 'when the ttl is too high' do
        let(:variable_ttl) { 43201 }
        include_examples 'fails variable validation', ArgumentError
      end

      context 'when the ttl is too low' do
        let(:variable_ttl) { 899 }
        include_examples 'fails variable validation', ArgumentError
      end
    end

    context 'when the method is any other value' do
      let(:variable_method) { 'test' }
      include_examples 'fails variable validation', ArgumentError
    end
  end

  describe '#mask_sensitive_data_in_response' do
    let(:response) do
      {
        data: {
          "access_key_id" => "AKIAIOSFODNN7EXAMPLE",
          "secret_access_key" => secret_access_key
        }
      }
    end
    let(:secret_access_key) { "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" }

    it 'masks the sensitive fields (secret_access_key)' do
      expect(subject.mask_sensitive_data_in_response(response))
        .not_to include(secret_access_key)
    end

    context 'when the response is an array' do
      let(:response) do
        [
          {
            data: {
              "access_key_id" => "AKIAIOSFODNN7EXAMPLE",
              "secret_access_key" => secret_access_key
            }
          },
          {
            data: {
              "access_key_id" => "AKIAIOSFODNN7EXAMPLE",
              "secret_access_key" => secret_access_key
            }
          }
        ]
      end

      it 'masks all instances the sensitive fields (secret_access_key)' do
        results = subject.mask_sensitive_data_in_response(response)
        results.each do |result|
          expect(result).not_to include(secret_access_key)
        end
      end
    end

    context 'when the response does not contain the data field' do
      let(:response) { { test: "test"} }

      it 'returns the response as is' do
        expect(subject.mask_sensitive_data_in_response(response))
          .to eq(response)
      end
    end
  end

  describe '#handle_minimum' do
    let(:issuer) do
      Issuer.new(
        issuer_id: id,
        max_ttl: max_ttl,
        issuer_type: type,
        data: data.to_json
      )
    end

    it 'returns the minimum fields for the issuer' do
      expect(subject.handle_minimum(issuer))
        .to eq(
          [
            "fetch minimum",
            { "max_ttl" => max_ttl }
          ]
        )
    end
  end
end
