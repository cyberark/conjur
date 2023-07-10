require 'spec_helper'

require 'conjur/rack/path_prefix'

describe Conjur::Rack::PathPrefix do
  let(:app) { double(:app) }
  let(:prefix) { "/api" }
  let(:path_prefix) { Conjur::Rack::PathPrefix.new(app, prefix) }
  let(:call) { path_prefix.call env }
  let(:env) {
    {
      'PATH_INFO' => path
    }
  }

  context "#call" do
    context "/api/hosts" do
      let(:path) { "/api/hosts" }
      it "matches" do
        expect(app).to receive(:call).with({ 'PATH_INFO' => '/hosts' }).and_return app
        call
      end
    end
    context "/api" do
      let(:path) { "/api" }
      it "doesn't erase the path completely" do
        expect(app).to receive(:call).with({ 'PATH_INFO' => '/' }).and_return app
        call
      end
    end
    context "with non-matching prefix" do
      let(:path) { "/hosts" }
      it "doesn't match" do
        expect(app).to receive(:call).with({ 'PATH_INFO' => '/hosts' }).and_return app
        call
      end
    end
  end
  
end