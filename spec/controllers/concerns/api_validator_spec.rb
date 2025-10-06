# spec/controllers/concerns/api_validator_spec.rb
require 'spec_helper'

class DummyController
  include APIValidator

  attr_accessor :request

  def initialize(headers = {})
    @request = OpenStruct.new(headers: headers)
  end
end

RSpec.describe(APIValidator) do
  let(:controller) { DummyController.new(headers) }

  context 'when Accept header is valid' do
    let(:headers) { { "Accept" => "application/x.secretsmgr.v2beta+json" } }

    it 'does not raise error' do
      expect { controller.validate_header }.not_to raise_error
    end
  end

  context 'when Accept header is invalid' do
    let(:headers) { { "Accept" => "application/x.secretsmgr.v1+json" } }

    it 'raises Errors::Conjur::APIHeaderMissing' do
      expect { controller.validate_header }.to raise_error(Errors::Conjur::APIHeaderMissing)
    end
  end

  context 'when Accept header is invalid not having beta' do
    let(:headers) { { "Accept" => "application/x.secretsmgr.v2+json" } }

    it 'raises Errors::Conjur::APIHeaderMissing' do
      expect { controller.validate_header }.to raise_error(Errors::Conjur::APIHeaderMissing)
    end
  end

  context 'when Accept header is missing' do
    let(:headers) { {} }

    it 'raises Errors::Conjur::APIHeaderMissing' do
      expect { controller.validate_header }.to raise_error(Errors::Conjur::APIHeaderMissing)
    end
  end
end
