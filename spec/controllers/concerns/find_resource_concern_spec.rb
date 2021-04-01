# frozen_string_literal: true

describe FindResource do
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

  let(:resource_id) { 'test:kind:resource' }

  # Test controller class
  class Controller
    include FindResource
  end
  subject(:controller) { Controller.new }
end
