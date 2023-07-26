# frozen_string_literal: true
require 'spec_helper'

describe FindEdgePolicyResource do
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
    allow(controller).to receive(:account).and_return('rspec')
    mock_user = double('User', id: 456)
    allow(controller).to receive(:current_user).and_return(mock_user)
    allow(controller).to receive(:is_role_member_of_group).and_return(false)
  end

  let(:resource_id) { 'test:kind:resource' }

  # Test controller class
  class Controller
    include FindEdgePolicyResource
  end

  subject(:controller) { Controller.new }
end
