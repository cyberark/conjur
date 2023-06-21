require 'spec_helper'

describe Slosilo::Keystore do
  include_context "with example key"
  include_context "with mock adapter"
  
  describe '#put' do
    it "handles Slosilo::Keys" do
      subject.put(:test, key)
      expect(adapter['test'].to_der).to eq(rsa.to_der)
    end

    it "refuses to store a key with a nil id" do
      expect { subject.put(nil, key) }.to raise_error(ArgumentError)
    end

    it "refuses to store a key with an empty id" do
      expect { subject.put('', key) }.to raise_error(ArgumentError)
    end

    it "passes the Slosilo key to the adapter" do
      expect(adapter).to receive(:put_key).with "test", key
      subject.put :test, key
    end
  end
end
