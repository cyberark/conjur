# frozen_string_literal: true

require 'spec_helper'

describe BodyParser do
  describe "#body_params" do
    context "with an unrecognized content type" do
      let(:media_type) { 'application/octet-stream' }
      it "returns an empty hash" do
        expect(controller.body_params).to eq({})
      end
    end

    shared_context "urlencoded form data" do
      let(:body_data) { "id=foo&test=bar%20baz&plus=one+two" }
      it "parses the body parameters" do
        expect(controller.body_params).to eq \
          'id' => 'foo',
          'test' => 'bar baz',
          'plus' => 'one two'
      end
    end

    context "with no explicit content type" do
      let(:media_type) { nil }
      include_context "urlencoded form data"
    end

    context "with form data content type" do
      let(:media_type) { 'application/x-www-form-urlencoded' }
      include_context "urlencoded form data"
    end

    context "with json media type" do
      let(:media_type) { 'application/json' }
      let(:body_data) { '{"foo": "bar" }' }
      it "attempts to parse as JSON" do
        expect(controller.body_params).to eq "foo" => "bar"
      end
    end

    it "returns a hash with indifferent access" do
      expect(controller.body_params[:id]).to eq 'foo'
    end
  end

  describe '#params' do
    it "merges the body params with others" do
      params_hash = controller.params.permit(:get, :id).to_h
      expect(params_hash).to include({'get' => 'params', 'id' => 'foo'})
    end
  end

  subject(:controller) do
    base = Class.new do
      # :reek:UtilityFunction
      def params
        ActionController::Parameters.new 'get' => 'params'
      end
    end
    Class.new(base) { include BodyParser }.new
  end

  before { allow(request).to receive(:body) { StringIO.new body_data } }
  before { allow(controller).to receive(:request) { request } }
  let(:media_type) { 'application/x-www-form-urlencoded' }
  let(:body_data) { "id=foo&test=bar%20baz&plus=one+two" }
  let(:request) { instance_double Rack::Request, media_type: media_type }
end
