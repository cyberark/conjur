require 'spec_helper'
require 'tmpdir'

require 'slosilo/adapters/file_adapter'

describe Slosilo::Adapters::FileAdapter do
  include_context "with example key"

  let(:dir) { Dir.mktmpdir }
  let(:adapter) { Slosilo::Adapters::FileAdapter.new dir }
  subject { adapter }
  
  describe "#get_key" do
    context "when given key does not exist" do
      it "returns nil" do
        expect(subject.get_key(:whatever)).not_to be
      end
    end
  end
  
  describe "#put_key" do
    context "unacceptable id" do
      let(:id) { "foo.bar" }
      it "isn't accepted" do
        expect { subject.put_key id, key }.to raise_error /id should not contain a period/
      end    
    end
    context "acceptable id" do
      let(:id) { "id" }
      let(:key_encrypted) { "encrypted key" }
      let(:fname) { "#{dir}/#{id}.key" }
      it "creates the key" do
        expect(Slosilo::EncryptedAttributes).to receive(:encrypt).with(key.to_der).and_return key_encrypted
        expect(File).to receive(:write).with(fname, key_encrypted)
        expect(File).to receive(:chmod).with(0400, fname)
        subject.put_key id, key
        expect(subject.instance_variable_get("@keys")[id]).to eq(key)
      end    
    end
  end
  
  describe "#each" do
    before { adapter.instance_variable_set("@keys", one: :onek, two: :twok) }
    
    it "iterates over each key" do
      results = []
      adapter.each { |id,k| results << { id => k } }
      expect(results).to eq([ { one: :onek}, {two: :twok } ])
    end
  end

  context 'with real key store' do
    let(:id) { 'some id' }

    before do
      Slosilo::encryption_key = Slosilo::Symmetric.new.random_key
      pre_adapter = Slosilo::Adapters::FileAdapter.new dir
      pre_adapter.put_key(id, key)
    end

    describe '#get_key' do
      it "loads and decrypts the key" do
        expect(adapter.get_key(id)).to eq(key)
      end
    end

    describe '#get_by_fingerprint' do
      it "can look up a key by a fingerprint" do
        expect(adapter.get_by_fingerprint(key_fingerprint)).to eq([key, id])
      end
    end
    
    describe '#each' do
      it "enumerates the keys" do
        results = []
        adapter.each { |id,k| results << { id => k } }
        expect(results).to eq([ { id => key } ])
      end
    end
  end
end
