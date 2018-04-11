require 'spec_helper'

describe Conjur::HasAttributes do
  class ObjectWithAttributes
    include Conjur::HasAttributes

    def id; "the-object"; end
    def credentials; {}; end
    def username; 'alice'; end
    def url; 'http://example.com/the-object'; end
  end

  def new_object
    ObjectWithAttributes.new
  end

  let(:object) { new_object }
  let(:second_object) { new_object }
  let(:attributes) { { 'id' => 'the-id' } }
  let(:rbac_resource_resource) { double(:rbac_resource_resource, url: object.url) }

  before {
    allow(object).to receive(:url_for).with(:resources_resource, {}, "the-object").and_return(rbac_resource_resource)
    allow(second_object).to receive(:url_for).with(:resources_resource, {}, "the-object").and_return(rbac_resource_resource)
    expect(rbac_resource_resource).to receive(:get).with(no_args).and_return(double(:response, body: attributes.to_json))
  }

  it "should fetch attributes from the server" do
    expect(object.attributes).to eq(attributes)
  end

  describe "caching" do
    let(:cache) {
      Struct.new(:dummy) do
        def table; @table ||= Hash.new; end

        def fetch_attributes cache_key, &block
          table[cache_key] || table[cache_key] = yield
        end
      end.new
    }

    around do |example|
      saved = Conjur.cache
      Conjur.cache = cache

      begin
        example.run
      ensure
        Conjur.cache = saved
      end
    end
    context "enabled" do
      it "caches the attributes across objects" do
        expect(object.attributes).to eq(attributes)
        expect(second_object.attributes).to eq(attributes)
        expect(cache.table).to eq({
          "alice.http://example.com/the-object" => attributes
        })
      end
    end
  end
end
