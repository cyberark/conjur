require 'spec_helper'

require 'active_support'
require 'active_support/core_ext/numeric/time'

describe Slosilo::Key do
  include_context "with example key"
  
  subject { key }

  describe '#to_der' do
    subject { super().to_der }
    it { is_expected.to eq(rsa.to_der) }
  end

  describe '#to_s' do
    subject { super().to_s }
    it { is_expected.to eq(rsa.public_key.to_pem) }
  end

  describe '#fingerprint' do
    subject { super().fingerprint }
    it { is_expected.to eq(key_fingerprint) }
  end
  it { is_expected.to be_private }

  context "with identical key" do
    let(:other) { Slosilo::Key.new rsa.to_der }
    it "is equal" do
      expect(subject).to eq(other)
    end

    it "is eql?" do
      expect(subject.eql?(other)).to be_truthy
    end

    it "has equal hash" do
      expect(subject.hash).to eq(other.hash)
    end
  end
  
  context "with a different key" do
    let(:other) { Slosilo::Key.new another_rsa }
    it "is not equal" do
      expect(subject).not_to eq(other)
    end

    it "is not eql?" do
      expect(subject.eql?(other)).not_to be_truthy
    end

    it "has different hash" do
      expect(subject.hash).not_to eq(other.hash)
    end
  end

  describe '#public' do
    it "returns a key with just the public half" do
      pkey = subject.public
      expect(pkey).to be_a(Slosilo::Key)
      expect(pkey).to_not be_private
      expect(pkey.key).to_not be_private
      expect(pkey.to_der).to eq(rsa.public_key.to_der)
    end
  end

  let(:plaintext) { 'quick brown fox jumped over the lazy dog' }
  describe '#encrypt' do
    it "generates a symmetric encryption key and encrypts the plaintext with the public key" do
      ctxt, skey = subject.encrypt plaintext
      pskey = rsa.private_decrypt skey
      expect(Slosilo::Symmetric.new.decrypt(ctxt, key: pskey)).to eq(plaintext)
    end
  end

  describe '#encrypt_message' do
    it "#encrypts a message and then returns the result as a single string" do
      expect(subject).to receive(:encrypt).with(plaintext).and_return ['fake ciphertext', 'fake key']
      expect(subject.encrypt_message(plaintext)).to eq('fake keyfake ciphertext')
    end
  end
  
  let(:ciphertext){ "G\xAD^\x17\x11\xBBQ9-b\x14\xF6\x92#Q0x\xF4\xAD\x1A\x92\xC3VZW\x89\x8E\x8Fg\x93\x05B\xF8\xD6O\xCFGCTp\b~\x916\xA3\x9AN\x8D\x961\x1F\xA3mSf&\xAD\xA77/]z\xA89\x01\xA7\xA9\x92\f".force_encoding('ASCII-8BIT') }
  let(:skey){  "\x82\x93\xFAA\xA6wQA\xE1\xB5\xA6b\x8C.\xCF#I\x86I\x83u\x99\rTA\xEF\xC4\x91\xC5)-\xEBQ\xB1\xC0\xC6\xFF\x90L\xFE\x1E\x15\x81\x12\x16\xDD:A\xC5d\xE1B\xD2f@\xB8o\xB7+N\xB7\n\x92\xDC\x9E\xE3\x83\xB8>h\a\xC7\xCC\xCF\xD0t\x06\x8B\xA8\xBF\xEFe\xA4{\x88\f\xDD\roF\xEB.\xDA\xBF\x9D_0>\xF03c'\x1F!)*-\x19\x97\xAC\xD2\x1F(,6h\a\x93\xDB\x8E\x97\xF9\x1A\x11\x84\x11t\xD9\xB2\x85\xB0\x12\x7F\x03\x00O\x8F\xBE#\xFFb\xA5w\xF3g\xCF\xB4\xF2\xB7\xDBiA=\xA8\xFD1\xEC\xBF\xD7\x8E\xB6W>\x03\xACNBa\xBF\xFD\xC6\xB32\x8C\xE2\xF1\x87\x9C\xAE6\xD1\x12\vkl\xBB\xA0\xED\x9A\xEE6\xF2\xD9\xB4LL\xE2h/u_\xA1i=\x11x\x8DGha\x8EG\b+\x84[\x87\x8E\x01\x0E\xA5\xB0\x9F\xE9vSl\x18\xF3\xEA\xF4NH\xA8\xF1\x81\xBB\x98\x01\xE8p]\x18\x11f\xA3K\xA87c\xBB\x13X~K\xA2".force_encoding('ASCII-8BIT') }
  describe '#decrypt' do
    it "decrypts the symmetric key and then uses it to decrypt the ciphertext" do
      expect(subject.decrypt(ciphertext, skey)).to eq(plaintext)
    end
  end
  
  describe '#decrypt_message' do
    it "splits the message into key and rest, then #decrypts it" do
      expect(subject).to receive(:decrypt).with(ciphertext, skey).and_return plaintext
      expect(subject.decrypt_message(skey + ciphertext)).to eq(plaintext)
    end
  end

  describe '#initialize' do
    context "when no argument given" do
      subject { Slosilo::Key.new }
      let (:rsa) { double "key" }
      it "generates a new key pair" do
        expect(OpenSSL::PKey::RSA).to receive(:new).with(2048).and_return(rsa)
        expect(subject.key).to eq(rsa)
      end
    end
    context "when given an armored key" do
      subject { Slosilo::Key.new rsa.to_der }

      describe '#to_der' do
        subject { super().to_der }
        it { is_expected.to eq(rsa.to_der) }
      end
    end
    context "when given a key instance" do
      subject { Slosilo::Key.new rsa }

      describe '#to_der' do
        subject { super().to_der }
        it { is_expected.to eq(rsa.to_der) }
      end
    end
    context "when given something else" do
      subject { Slosilo::Key.new "foo" }
      it "fails early" do
        expect { subject }.to raise_error ArgumentError
      end
    end
  end
  
  describe "#sign" do
    context "when given a hash" do
      it "converts to a sorted array and signs that" do
        expect(key).to receive(:sign_string).with '[["a",3],["b",42]]'
        key.sign b: 42, a: 3
      end
    end
    context "when given an array" do
      it "signs a JSON representation instead" do
        expect(key).to receive(:sign_string).with '[2,[42,2]]'
        key.sign [2, [42, 2]]
      end
    end
    context "when given a string" do
      let(:expected_signature) { "d[\xA4\x00\x02\xC5\x17\xF5P\x1AD\x91\xF9\xC1\x00P\x0EG\x14,IN\xDE\x17\xE1\xA2a\xCC\xABR\x99'\xB0A\xF5~\x93M/\x95-B\xB1\xB6\x92!\x1E\xEA\x9C\v\xC2O\xA8\x91\x1C\xF9\x11\x92a\xBFxm-\x93\x9C\xBBoM\x92%\xA9\xD06$\xC1\xBC.`\xF8\x03J\x16\xE1\xB0c\xDD\xBF\xB0\xAA\xD7\xD4\xF4\xFC\e*\xAB\x13A%-\xD3\t\xA5R\x18\x01let6\xC8\xE9\"\x7F6O\xC7p\x82\xAB\x04J(IY\xAA]b\xA4'\xD6\x873`\xAB\x13\x95g\x9C\x17\xCAB\xF8\xB9\x85B:^\xC5XY^\x03\xEA\xB6V\x17b2\xCA\xF5\xD6\xD4\xD2\xE3u\x11\xECQ\x0Fb\x14\xE2\x04\xE1<a\xC5\x01eW-\x15\x01X\x81K\x1A\xE5A\vVj\xBF\xFC\xFE#\xD5\x93y\x16\xDC\xB4\x8C\xF0\x02Y\xA8\x87i\x01qC\xA7#\xE8\f\xA5\xF0c\xDEJ\xB0\xDB BJ\x87\xA4\xB0\x92\x80\x03\x95\xEE\xE9\xB8K\xC0\xE3JbE-\xD4\xCBP\\\x13S\"\eZ\xE1\x93\xFDa pinch of salt".force_encoding("ASCII-8BIT") }
      it "signs it" do
        allow(key).to receive_messages shake_salt: 'a pinch of salt'
        expect(key.sign("this sentence is not this sentence")).to eq(expected_signature)
      end
    end

    context "when given a Hash containing non-ascii characters" do
      let(:unicode){ "adèle.dupuis" }
      let(:encoded){
        unicode.dup.tap{|s| s.force_encoding Encoding::ASCII_8BIT}
      }
      let(:hash){ {"data" => unicode} }

      it "converts the value to raw bytes before signing it" do
        expect(key).to receive(:sign_string).with("[[\"data\",\"#{encoded}\"]]").and_call_original
        key.sign hash
      end
    end
  end
  
  describe "#signed_token" do
    let(:time) { Time.new(2012,1,1,1,1,1,0) }
    let(:data) { { "foo" => :bar } }
    let(:token_to_sign) { { "data" => data, "timestamp" => "2012-01-01 01:01:01 UTC" } }
    let(:signature) { "signature" }
    let(:salt) { 'a pinch of salt' }
    let(:expected_signature) { Base64::urlsafe_encode64 "\xB0\xCE{\x9FP\xEDV\x9C\xE7b\x8B[\xFAil\x87^\x96\x17Z\x97\x1D\xC2?B\x96\x9C\x8Ep-\xDF_\x8F\xC21\xD9^\xBC\n\x16\x04\x8DJ\xF6\xAF-\xEC\xAD\x03\xF9\xEE:\xDF\xB5\x8F\xF9\xF6\x81m\xAB\x9C\xAB1\x1E\x837\x8C\xFB\xA8P\xA8<\xEA\x1Dx\xCEd\xED\x84f\xA7\xB5t`\x96\xCC\x0F\xA9t\x8B\x9Fo\xBF\x92K\xFA\xFD\xC5?\x8F\xC68t\xBC\x9F\xDE\n$\xCA\xD2\x8F\x96\x0EtX2\x8Cl\x1E\x8Aa\r\x8D\xCAi\x86\x1A\xBD\x1D\xF7\xBC\x8561j\x91YlO\xFA(\x98\x10iq\xCC\xAF\x9BV\xC6\v\xBC\x10Xm\xCD\xFE\xAD=\xAA\x95,\xB4\xF7\xE8W\xB8\x83;\x81\x88\xE6\x01\xBA\xA5F\x91\x17\f\xCE\x80\x8E\v\x83\x9D<\x0E\x83\xF6\x8D\x03\xC0\xE8A\xD7\x90i\x1D\x030VA\x906D\x10\xA0\xDE\x12\xEF\x06M\xD8\x8B\xA9W\xC8\x9DTc\x8AJ\xA4\xC0\xD3!\xFA\x14\x89\xD1p\xB4J7\xA5\x04\xC2l\xDC8<\x04Y\xD8\xA4\xFB[\x89\xB1\xEC\xDA\xB8\xD7\xEA\x03Ja pinch of salt".force_encoding("ASCII-8BIT") }
    let(:expected_token) { token_to_sign.merge "signature" => expected_signature, "key" => key_fingerprint }
    before do
      allow(key).to receive_messages shake_salt: salt
      allow(Time).to receive_messages new: time
    end
    subject { key.signed_token data }
    it { is_expected.to eq(expected_token) }
  end

  describe "#validate_jwt" do
    let(:token) do
      instance_double Slosilo::JWT,
          header: { 'alg' => 'conjur.org/slosilo/v2' },
          claims: { 'iat' => Time.now.to_i },
          string_to_sign: double("string to sign"),
          signature: double("signature")
    end

    before do
      allow(key).to receive(:verify_signature).with(token.string_to_sign, token.signature) { true }
    end

    it "verifies the signature" do
      expect { key.validate_jwt token }.not_to raise_error
    end

    it "rejects unknown algorithm" do
      token.header['alg'] = 'HS256' # we're not supporting standard algorithms
      expect { key.validate_jwt token }.to raise_error /algorithm/
    end

    it "rejects bad signature" do
      allow(key).to receive(:verify_signature).with(token.string_to_sign, token.signature) { false }
      expect { key.validate_jwt token }.to raise_error /signature/
    end

    it "rejects expired token" do
      token.claims['exp'] = 1.hour.ago.to_i
      expect { key.validate_jwt token }.to raise_error /expired/
    end

    it "accepts unexpired token with implicit expiration" do
      token.claims['iat'] = 5.minutes.ago
      expect { key.validate_jwt token }.to_not raise_error
    end

    it "rejects token expired with implicit expiration" do
      token.claims['iat'] = 10.minutes.ago.to_i
      expect { key.validate_jwt token }.to raise_error /expired/
    end
  end

  describe "#token_valid?" do
    let(:data) { { "foo" => :bar } }
    let(:signature) { Base64::urlsafe_encode64 "\xB0\xCE{\x9FP\xEDV\x9C\xE7b\x8B[\xFAil\x87^\x96\x17Z\x97\x1D\xC2?B\x96\x9C\x8Ep-\xDF_\x8F\xC21\xD9^\xBC\n\x16\x04\x8DJ\xF6\xAF-\xEC\xAD\x03\xF9\xEE:\xDF\xB5\x8F\xF9\xF6\x81m\xAB\x9C\xAB1\x1E\x837\x8C\xFB\xA8P\xA8<\xEA\x1Dx\xCEd\xED\x84f\xA7\xB5t`\x96\xCC\x0F\xA9t\x8B\x9Fo\xBF\x92K\xFA\xFD\xC5?\x8F\xC68t\xBC\x9F\xDE\n$\xCA\xD2\x8F\x96\x0EtX2\x8Cl\x1E\x8Aa\r\x8D\xCAi\x86\x1A\xBD\x1D\xF7\xBC\x8561j\x91YlO\xFA(\x98\x10iq\xCC\xAF\x9BV\xC6\v\xBC\x10Xm\xCD\xFE\xAD=\xAA\x95,\xB4\xF7\xE8W\xB8\x83;\x81\x88\xE6\x01\xBA\xA5F\x91\x17\f\xCE\x80\x8E\v\x83\x9D<\x0E\x83\xF6\x8D\x03\xC0\xE8A\xD7\x90i\x1D\x030VA\x906D\x10\xA0\xDE\x12\xEF\x06M\xD8\x8B\xA9W\xC8\x9DTc\x8AJ\xA4\xC0\xD3!\xFA\x14\x89\xD1p\xB4J7\xA5\x04\xC2l\xDC8<\x04Y\xD8\xA4\xFB[\x89\xB1\xEC\xDA\xB8\xD7\xEA\x03Ja pinch of salt".force_encoding("ASCII-8BIT") }
    let(:token) { { "data" => data, "timestamp" => "2012-01-01 01:01:01 UTC", "signature" => signature } }
    before { allow(Time).to receive_messages now: Time.new(2012,1,1,1,2,1,0) }
    subject { key.token_valid? token }
    it { is_expected.to be_truthy }
    
    it "doesn't check signature on the advisory key field" do
      expect(key.token_valid?(token.merge "key" => key_fingerprint)).to be_truthy
    end
    
    it "rejects the token if the key field is present and doesn't match" do
      expect(key.token_valid?(token.merge "key" => "this is not the key you are looking for")).not_to be_truthy
    end
    
    context "when token is 1 hour old" do
      before { allow(Time).to receive_messages now: Time.new(2012,1,1,2,1,1,0) }
      it { is_expected.to be_falsey }
      context "when timestamp in the token is changed accordingly" do
        let(:token) { { "data" => data, "timestamp" => "2012-01-01 02:00:01 UTC", "signature" => signature } }
        it { is_expected.to be_falsey }
      end
    end
    context "when the data is changed" do
      let(:data) { { "foo" => :baz } }
      it { is_expected.to be_falsey }
    end
    context "when RSA decrypt raises an error" do
      before { expect_any_instance_of(OpenSSL::PKey::RSA).to receive(:public_decrypt).and_raise(OpenSSL::PKey::RSAError) }
      it { is_expected.to be_falsey }
    end
  end
end
