# frozen_string_literal: true

require 'spec_helper'

describe Anyway::Loaders::SpringConfigLoader do

  context 'fetch config' do
    before do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with('TENANT_PROFILES').and_return('us-east-1,us-east-1-my-tenant')
    end

    # @param: props_by_source: array of pairs
    def config_response(propery_sources)
      {name: "conjur",
       profiles: ["us-east", "us-east-my-tenant"],
       propertySources: propery_sources}.to_json
    end

    it 'gathers values from different property sources' do
      property_sources = (1..3).map{|i| {source: {"feature#{i}" => "great_feature"}}}
      expect(Net::HTTP).to receive(:get).and_return(config_response(property_sources))

      expect(described_class.fetch_configs).to eq({'feature1' => 'great_feature', 'feature2' => 'great_feature', 'feature3' => 'great_feature'})
    end

    it "overrides value across property sources" do
      property_sources = (1..3).to_a.reverse.map{|i| {source: {"feature" => "value_#{i}"}}}
      expect(Net::HTTP).to receive(:get).and_return(config_response(property_sources))

      expect(described_class.fetch_configs).to eq({'feature' => "value_3"})
    end

    it "handles gitops branch" do
      expect(described_class.send(:build_uri, 'http://confy', 'appy', 'profy').to_s).to eq('http://confy/appy/profy')

      allow(ENV).to receive(:[]).with('GITOPS_BRANCH').and_return('branchy')
      expect(described_class.send(:build_uri, 'http://confy', 'appy', 'profy').to_s).to eq('http://confy/appy/profy/branchy')
    end

    it "raises exception when config server is unavailable" do
      expect(Net::HTTP).to receive(:get).and_raise(HTTP::ConnectionError)
      expect{described_class.fetch_configs}.to raise_error(HTTP::ConnectionError)
    end
  end
end
