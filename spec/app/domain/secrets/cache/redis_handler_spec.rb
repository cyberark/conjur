# frozen_string_literal: true
require 'spec_helper'

describe Secrets::RedisHandler do

  context "Encryption - Decryption" do

    let(:key) {"key"}
    let(:value) {"value"}

    it "Encryption is called on write" do
      expect(Slosilo::EncryptedAttributes).to receive(:encrypt).with(value, aad: key)
      controller.send(:write_resource, key, value)
    end

    it "Decryption is called on read" do
      controller.send(:write_resource, key, value)
      expect(Slosilo::EncryptedAttributes).to receive(:decrypt)
      controller.send(:read_resource, key)
    end

    it "data is preserved through encrypt + decrypt" do
      controller.send(:write_resource, key, value)
      expect(controller.send(:read_resource, key)).to eq(value)
    end

  end
  class Controller
    include Secrets::RedisHandler
  end

  subject(:controller) { Controller.new }
end

