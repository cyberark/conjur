# frozen_string_literal: true

require 'spec_helper'

module Authentication
  module KlassTest
    module V2
      class Strategy
      end

      module DataObjects
        class Authenticator
        end
      end

      module Validations
        class AuthenticatorConfiguration
        end
      end
    end
  end
end

RSpec.describe(Authentication::Util::V2::KlassLoader) do
  let(:namespace_selector) do
    class_double(Authentication::Util::NamespaceSelector).tap do |double|
      allow(double).to receive(:type_to_module).with(authenticator_type).and_return(authenticator_module)
    end
  end
  let(:authenticator_module) { authenticator_type.underscore.camelcase }

  let(:loader) { described_class.new(authenticator_type, namespace_selector: namespace_selector) }
  let(:authenticator_type) { 'klass-test' }
  describe '.strategy' do
    context 'when the strategy class exists' do
      it 'returns the desired class' do
        expect(loader.strategy).to eq(Authentication::KlassTest::V2::Strategy)
      end
    end
    context 'when the strategy class does not exist' do
      let(:authenticator_type) { 'Foo' }
      it 'returns a null value' do
        expect(loader.strategy).to eq(nil)
      end
    end
  end
  describe '.authenticator_validation' do
    context 'when the strategy class exists' do
      it 'returns the desired class' do
        expect(loader.authenticator_validation).to eq(Authentication::KlassTest::V2::Validations::AuthenticatorConfiguration)
      end
    end
    context 'when the strategy class does not exist' do
      let(:authenticator_type) { 'Foo' }
      it 'returns a null value' do
        expect(loader.authenticator_validation).to eq(nil)
      end
    end
  end
  describe '.data_object' do
    context 'when the strategy class exists' do
      it 'returns the desired class' do
        expect(loader.data_object).to eq(Authentication::KlassTest::V2::DataObjects::Authenticator)
      end
    end
    context 'when the strategy class does not exist' do
      let(:authenticator_type) { 'Foo' }
      it 'returns a null value' do
        expect(loader.data_object).to eq(nil)
      end
    end
  end
end
