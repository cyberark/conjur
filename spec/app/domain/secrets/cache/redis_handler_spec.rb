# frozen_string_literal: true
require 'spec_helper'

describe Secrets::RedisHandler do

  context "Encryption - Decryption" do

    let(:key) {"key"}
    let(:value) {"value"}

    it "Encryption is called on write" do
      expect(Slosilo::EncryptedAttributes).to receive(:encrypt).with(value, aad: key)
      controller.send(:write_secret, key, value)
    end

    it "Decryption is called on read" do
      controller.send(:write_secret, key, value)
      expect(Slosilo::EncryptedAttributes).to receive(:decrypt)
      controller.send(:read_secret, key)
    end

    it "data is preserved through encrypt + decrypt" do
      controller.send(:write_secret, key, value)
      expect(controller.send(:read_secret, key)).to eq(value)
    end

  end

  context "Resource redis" do
    let(:key) {"key"}
    let(:value) {"value"}

    it "write_resource is called on write" do
      expect(Rails.cache).to receive(:write).with("secrets/resource/#{key}", value)
      controller.send(:write_resource, key, value)
    end

    it "read_resource is called on read" do
      expect(Rails.cache).to receive(:read).with("secrets/resource/#{key}")
      controller.send(:read_resource, key)
    end
  end

  context "Secret version" do
    let(:key) {"data/key"}
    let(:value) {"value"}
    let(:version) { "5" }

    before do
      Rails.cache.clear
      # Effectively overrides encrypt/decrypt
      allow(Slosilo::EncryptedAttributes).to receive(:decrypt).and_wrap_original {|original, *args| args.first }
      allow(Slosilo::EncryptedAttributes).to receive(:encrypt).and_wrap_original {|original, *args| args.first }
    end

    it "get with version returns correct version" do
      controller.create_redis_secret(key, "1", "", "1")
      controller.create_redis_secret(key, "2", "", "2")
      expect(Rails.cache).to receive(:read).with("#{key}?version=1").and_call_original
      expect(Rails.cache).to receive(:read).with("#{key}/mime_type").and_call_original
      secret, _ = controller.get_redis_secret(key, "1")
      expect(secret).to eq("1")
    end

    it "get without version returns latest version" do
      controller.create_redis_secret(key, "1", nil)
      controller.create_redis_secret(key, "2", nil)
      expect(Rails.cache).to receive(:read).with("#{key}").and_call_original
      expect(Rails.cache).to receive(:read).with("#{key}/mime_type").and_call_original
      secret, _ = controller.get_redis_secret(key)
      expect(secret).to eq("2")
    end

    it "create with version" do
      expect(Rails.cache).to receive(:write).with("#{key}?version=#{version}", anything)
      expect(Rails.cache).to receive(:write).with("#{key}/mime_type", anything)
      controller.create_redis_secret(key, value, nil, version)
    end

    it "create updates latest version" do
      expect(Rails.cache).to receive(:write).with("#{key}", anything)
      expect(Rails.cache).to receive(:write).with("#{key}/mime_type", anything)
      controller.create_redis_secret(key, value, nil)
    end
  end

  class Controller
    include Secrets::RedisHandler
  end

  subject(:controller) { Controller.new }
end

