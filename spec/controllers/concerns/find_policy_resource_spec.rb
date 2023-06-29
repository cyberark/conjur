# frozen_string_literal: true
require 'spec_helper'

describe FindPolicyResource do
  context "when resource cannot be found" do
    let(:resource) { nil }
    describe '#resource' do
      it "raises an error" do
        expect { controller.send(:resource) }
          .to raise_error(Exceptions::RecordNotFound)
      end
    end
  end

  before do
    allow(Resource).to receive(:[]).with(resource_id).and_return(resource)
    allow(controller).to receive(:resource_id) { resource_id }
  end

  let(:resource_id) { 'test:policy:resource' }

  # Test controller class
  class Controller
    include FindPolicyResource
  end

  subject(:controller) { Controller.new }
end
