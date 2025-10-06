# frozen_string_literal: true

require 'spec_helper'

class DummyContract < Authentication::Base::Validations
  params do
    required(:foo).filled(:string)
    optional(:bar).filled(:string)
  end

  rule(:foo, :bar) do
    if values[:foo] == values[:bar]
      failed_response(
        key: key,
        error: StandardError.new('the values match')
      )
    end
  end
end

module Authentication
  module AuthnDummy
    module V2
      module Validations
        class AuthenticatorConfiguration < Authentication::Base::Validations
          params do
            required(:account).filled(:string)
            required(:service_id).filled(:string)
            required(:foo).filled(:string)

            optional(:bar).filled(:string)
          end
        end
      end
    end
  end
end

RSpec.describe(DB::Validation) do
  let(:validator) { described_class.new(contract) }

  describe('.validate') do
    context 'when no validations are provided' do
      let(:contract) { nil }
      it 'returns the provided data' do
        data = { foo: 'bar', bar: 'baz', bing: 'bang' }
        response = validator.validate(data)

        expect(response.success?).to be(true)
        expect(response.result).to eq(data)
      end
    end

    context 'when validation contract is present' do
      let(:contract) { DummyContract }
      context 'when provided data is valid' do
        it 'returns the provided data' do
          data = { foo: 'bar', bar: 'baz' }
          response = validator.validate(data)

          expect(response.success?).to be(true)
          expect(response.result).to eq(data)
        end
      end
      context 'when extra data is provided' do
        it 'returns only the defined data' do
          data = { foo: 'bar', bar: 'baz' }
          response = validator.validate(data.merge(baz: 'bing'))

          expect(response.success?).to be(true)
          expect(response.result).to eq(data)
        end
      end
      context 'when only required data is provided' do
        it 'returns the defined data' do
          response = validator.validate({ foo: 'bar' })

          expect(response.success?).to be(true)
          expect(response.result).to eq({ foo: 'bar' })
        end
      end
      context 'when data is missing' do
        it 'is unsuccessful' do
          response = validator.validate({ bar: 'foo' })

          expect(response.success?).to be(false)
          expect(response.message.text).to eq('is missing')
          expect(response.message.path).to eq([:foo])
        end
        context 'when the contract is a authenticator contract' do
          let(:contract) { Authentication::AuthnDummy::V2::Validations::AuthenticatorConfiguration }
          it 'is unsuccessful' do
            response = validator.validate({ account: 'rspec', service_id: 'tester', bar: 'baz' })

            expect(response.success?).to be(false)
            expect(response.message).to eq("Value 'foo' is missing")
            expect(response.exception.class).to eq(Errors::Conjur::RequiredSecretMissing)
            expect(response.exception.message).to eq(
              'CONJ00037E Missing value for resource: rspec:variable:conjur/authn-dummy/tester/foo'
            )
          end
        end
      end
      context 'when data is invalid' do
        it 'is unsuccessful' do
          response = validator.validate({ bar: 'baz', foo: 'baz' })

          expect(response.success?).to be(false)
          expect(response.message.to_s).to eq('the values match')
          expect(response.message.path).to eq([:foo])
          expect(response.exception.class).to eq(StandardError)
          expect(response.exception.message).to eq('the values match')
        end
      end
    end
  end
end
