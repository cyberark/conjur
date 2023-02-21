# frozen_string_literal: true

require 'spec_helper'

require './spec/app/domain/factory/shared.rb'

RSpec.describe(Factory::Templates::Authenticators::AuthnOidc) do
  subject { Factory::Templates::Authenticators::AuthnOidc }
  let(:available_properties) { %w[id variables] }
  let(:required_properties) { available_properties }

  let(:available_variables) { %w[claim-mapping client-id client-secret provider-uri redirect-uri] }
  let(:required_variables) { %w[claim-mapping client-id client-secret provider-uri] }

  describe('#data') do
    # Tests to ensure the integrity of the interface
    include_context 'factory schema'
    include_context 'factory schema with variables'
  end

  describe('#policy_template') do
    # Tests to ensure the integrity of the interface
    include_context 'policy template'
    # include_context 'factory schema with variables'
  end
end
