require 'spec_helper'

describe EdgeSecretsController, :type => :request do
  context "Get All Secrets" do
    it "with limit and offset" do
      options = Hash.new
      options[:offset] = "2"
      options[:limit] = "20"
      limit, offset = EdgeSecretsController.new.send(:get_offset_limit, options)
      expect(limit).to eq("20")
      expect(offset).to eq("2")
    end

    it "with limit" do
      options = Hash.new
      options[:limit] = "20"
      limit, offset = EdgeSecretsController.new.send(:get_offset_limit, options)
      expect(limit).to eq("20")
      expect(offset).to eq("0")
    end

    it "with offset" do
      options = Hash.new
      options[:offset] = "2"
      limit, offset = EdgeSecretsController.new.send(:get_offset_limit, options)
      expect(limit).to eq("1000")
      expect(offset).to eq("2")
    end

    it "without limit and offset" do
      options = Hash.new
      limit, offset = EdgeSecretsController.new.send(:get_offset_limit, options)
      expect(limit).to eq("1000")
      expect(offset).to eq("0")
    end
  end
end