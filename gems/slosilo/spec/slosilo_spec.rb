require 'spec_helper'

describe Slosilo do
  include_context "with mock adapter"
  include_context "with example key"
  before { Slosilo['test'] = key }
  
  describe '[]' do
    it "returns a Slosilo::Key" do
      expect(Slosilo[:test]).to be_instance_of Slosilo::Key
    end

    it "allows looking up by fingerprint" do
      expect(Slosilo[fingerprint: key_fingerprint]).to eq(key)
    end
    
    context "when the requested key does not exist" do
      it "returns nil instead of creating a new key" do
        expect(Slosilo[:aether]).not_to be
      end
    end
  end
  
  describe '.sign' do
    let(:own_key) { double "own key" }
    before { allow(Slosilo).to receive(:[]).with(:own).and_return own_key }
    let (:argument) { double "thing to sign" }
    it "fetches the own key and signs using that" do
      expect(own_key).to receive(:sign).with(argument)
      Slosilo.sign argument
    end
  end
  
  describe '.token_valid?' do
    before { allow(adapter['test']).to receive_messages token_valid?: false }
    let(:key2) { double "key 2", token_valid?: false }
    let(:key3) { double "key 3", token_valid?: false }
    before do
      adapter[:key2] = key2
      adapter[:key3] = key3
    end
    
    let(:token) { double "token" }
    subject { Slosilo.token_valid? token }
    
    context "when no key validates the token" do
      before { allow(Slosilo::Key).to receive_messages new: (double "key", token_valid?: false) }
      it { is_expected.to be_falsey }
    end
    
    context "when a key validates the token" do
      let(:valid_key) { double token_valid?: true }
      let(:invalid_key) { double token_valid?: true }
      before do
        allow(Slosilo::Key).to receive_messages new: invalid_key
        adapter[:key2] = valid_key
      end
      
      it { is_expected.to be_truthy }
    end
  end
  
  describe '.token_signer' do

    context "when token matches a key" do
      let(:token) {{ 'data' => 'foo', 'key' => key.fingerprint, 'signature' => 'XXX' }}

      context "and the signature is valid" do
        before { allow(key).to receive(:token_valid?).with(token).and_return true }

        it "returns the key id" do
          expect(subject.token_signer(token)).to eq('test')
        end
      end

      context "and the signature is invalid" do
        before { allow(key).to receive(:token_valid?).with(token).and_return false }

        it "returns nil" do
          expect(subject.token_signer(token)).not_to be
        end
      end
    end

    context "when token doesn't match a key" do
      let(:token) {{ 'data' => 'foo', 'key' => "footprint", 'signature' => 'XXX' }}
      it "returns nil" do
        expect(subject.token_signer(token)).not_to be
      end
    end

    context "with JWT token" do
      before do
        expect(key).to receive(:validate_jwt) do |jwt|
          expect(jwt.header).to eq 'kid' => key.fingerprint
          expect(jwt.claims).to eq({})
          expect(jwt.signature).to eq 'sig'
        end
      end

      it "accepts pre-parsed JSON serialization" do
        expect(Slosilo.token_signer(
          'protected' => 'eyJraWQiOiIxMDdiZGI4NTAxYzQxOWZhZDJmZGIyMGI0NjdkNGQwYTYyYTE2YTk4YzM1ZjJkYTBlYjNiMWZmOTI5Nzk1YWQ5In0=',
          'payload' => 'e30=',
          'signature' => 'c2ln'
        )).to eq 'test'
      end

      it "accepts pre-parsed JWT token" do
        expect(Slosilo.token_signer(Slosilo::JWT(
          'protected' => 'eyJraWQiOiIxMDdiZGI4NTAxYzQxOWZhZDJmZGIyMGI0NjdkNGQwYTYyYTE2YTk4YzM1ZjJkYTBlYjNiMWZmOTI5Nzk1YWQ5In0=',
          'payload' => 'e30=',
          'signature' => 'c2ln'
        ))).to eq 'test'
      end

      it "accepts compact serialization" do
        expect(Slosilo.token_signer(
          'eyJraWQiOiIxMDdiZGI4NTAxYzQxOWZhZDJmZGIyMGI0NjdkNGQwYTYyYTE2YTk4YzM1ZjJkYTBlYjNiMWZmOTI5Nzk1YWQ5In0=.e30=.c2ln'
        )).to eq 'test'
      end
    end
  end
end
