# frozen_string_literal: true

require 'spec_helper'
require 'rack/remember_uuid'

describe Rack::RememberUuid do
  let(:app) { ->(env){ } }
  subject(:middleware) { described_class.new(app) }

  # Reset the thread's `request_id`
  after(:each) do
    Thread.current[:request_id] = nil
  end

  # If the `X-Request-Id` header is set, then the thread's request_id
  # will be set to the header value. Otherwise it will be a Uuid set
  # by the function `action_dispatch.request_id`.
  context "when called with a GET request" do
    let(:request) { Rack::MockRequest.new(app) }

    context "with no x-request-id set" do
      let(:env) { { "action_dispatch.request_id"=> "mocked-uuid" } }

      it "default rails uuuid is passed on to Thread.current" do
        middleware.call(env)
        expect(Thread.current[:request_id]).to eq("mocked-uuid")
      end
    end

    context "with x-request-id set" do
      let(:env) { { "action_dispatch.request_id"=> "x-request-id-header" } }
      it "it copies the value to Thread.current" do
        middleware.call(env)
        expect(Thread.current[:request_id]).to eq("x-request-id-header")
      end
    end
  end
end
