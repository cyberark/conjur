# frozen_string_literal: true

require 'spec_helper'

describe "HostFactory" do
  include_context "create user"

  let(:login) { "the-user" }

  # idk why I need this... ???
  # Otherwise the records are being committed as they are created.
  # I thought use_transactional_fixtures took care of this.
  around(:each) do |example|
    Sequel::Model.db.transaction do
      example.run
      raise Sequel::Rollback
    end
  end
  
  before {
    layer_p = Conjur::PolicyParser::Types::Layer.new("the-layer")
    layer_p.owner = Conjur::PolicyParser::Types::Role.new(the_user.id)
    layer_p.account = "rspec"
    
    hf_p = Conjur::PolicyParser::Types::HostFactory.new("the-factory")
    hf_p.account = "rspec"
    hf_p.owner = Conjur::PolicyParser::Types::Role.new(the_user.id)
    hf_p.layers = []
    hf_p.layers << layer_p
    
    [ layer_p, hf_p ].each do |obj|
      Loader::Types.wrap(obj).create!
    end
  }
  
  let(:host_factory) { Resource["rspec:host_factory:the-factory"] }
  
  it "has expected JSON" do
    expect(host_factory.as_json).to match({
      "created_at" => an_instance_of(String),
      "id" => "rspec:host_factory:the-factory", 
      "owner" => "rspec:user:the-user",
      "annotations" => [], 
      "tokens" => [], 
      "layers" => ["rspec:layer:the-layer"],
      "permissions" => []
    })
  end
  
  it "has an associated role" do
    expect(host_factory.role).to be
    expect(host_factory.id).to eq(host_factory.role.id)
    expect(host_factory.role.resource).to eq(host_factory)
  end
  
  describe HostBuilder do
    let(:host_builder) { 
      HostBuilder.new("rspec", 
                      "host-01", 
                      host_factory.role,
                      host_factory.role.layers,
                      defined?(options) ? options : {})
    }
    let(:create_host) { host_builder.create_host }
    let(:host) { create_host[0] }
    let(:api_key) { create_host[1] }
    context "existing host" do
      it "must be owned by the host factory" do
        create_host
        host.owner = the_user
        host.save
        
        expect { host_builder.create_host }.to raise_error(Exceptions::Forbidden)
      end
      it "rotates the API key" do
        create_host
        host, rotated_api_key = host_builder.create_host
        
        expect(host).to eq(host)
        expect(rotated_api_key).to_not eq(api_key)
      end
    end
    context "created host" do
      it "is owned by the host factory role" do
        expect(host.owner).to eq(host_factory.role)
      end
      it "has the host factory layers" do
        expect(host.role.memberships_as_member.map(&:role)).to eq(host_factory.role.layers)
      end
    end

    describe 'verify create host given AUTHN_API_KEY config' do
      context 'when CONJUR_AUTHN_API_KEY_DEFAULT is true' do
        before do
          allow(Rails.application.config.conjur_config).to receive(:authn_api_key_default).and_return(true)
        end

        context 'when creating host with api-key annotation true' do
          let(:options) { {annotations: {'authn/api-key' => true}} }
          it { expect { host_builder.create_host }.to_not raise_error }
        end

        context 'when creating host with api-key annotation false' do
          let(:options) { {annotations: {'authn/api-key' => false}} }
          it { expect { host_builder.create_host }.to_not raise_error }
        end

        context 'when creating host without api-key annotation' do
          it { expect { host_builder.create_host }.to_not raise_error }
        end
      end

      context 'when CONJUR_AUTHN_API_KEY_DEFAULT is false' do
        before do
          allow(Rails.application.config.conjur_config).to receive(:authn_api_key_default).and_return(false)
        end

        context 'when creating host with api-key annotation true' do
          let(:options) { {annotations: {'authn/api-key' => true}} }
          it { expect { host_builder.create_host }.to_not raise_error }
        end

        context 'when creating host with api-key annotation false' do
          let(:options) { {annotations: {'authn/api-key' => false}} }
          it { expect { host_builder.create_host }.to raise_error }
        end

        context 'when creating host with api-key annotation False capital' do
          let(:options) { {annotations: {'authn/api-key' => "FALSE"}} }
          it { expect { host_builder.create_host }.to raise_error }
        end

        context 'when creating host without api-key annotation' do
          it { expect { host_builder.create_host }.to raise_error }
        end
      end
     end
  end
end
