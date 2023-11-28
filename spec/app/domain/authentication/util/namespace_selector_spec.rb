# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::Util::NamespaceSelector) do
  describe '#type_to_module', type: 'unit' do
    context 'when type is a supported authenticator type' do
      context 'when type is `authn-oidc`' do
        it 'returns the valid namespace' do
          expect(described_class.type_to_module('authn-oidc')).to eq('AuthnOidc')
        end
      end
      context 'when type is `authn`' do
        it 'returns the valid namespace' do
          expect(described_class.type_to_module('authn')).to eq('AuthnApiKey')
        end
      end
    end
    context 'when type is missing' do
      it 'raises an error' do
        expect { described_class.type_to_module(nil) }.to raise_error(
          RuntimeError,
          'Authenticator type is missing or nil'
        )
      end
    end
  end
end
