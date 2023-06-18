require 'spec_helper'
require 'slosilo/attr_encrypted'

describe Slosilo::EncryptedAttributes do
  before(:all) do
    Slosilo::encryption_key = OpenSSL::Cipher.new("aes-256-gcm").random_key
  end

  let(:aad) { proc{ |_| "hithere" } }

  let(:base){
    Class.new do
      attr_accessor :normal_ivar,:with_aad
      def stupid_ivar
        side_effect!
        @_explicit
      end
      def stupid_ivar= e
        side_effect!
        @_explicit = e
      end
      def side_effect!

      end
    end
  }

  let(:sub){
    Class.new(base) do
      attr_encrypted :normal_ivar, :stupid_ivar
    end
  }

  subject{ sub.new  }

  context "when setting a normal ivar" do
    let(:value){ "some value" }
    it "stores an encrypted value in the ivar" do
      subject.normal_ivar = value
      expect(subject.instance_variable_get(:"@normal_ivar")).to_not eq(value)
    end

    it "recovers the value set" do
      subject.normal_ivar = value
      expect(subject.normal_ivar).to eq(value)
    end
  end

  context "when setting an attribute with an implementation" do
    it "calls the base class method" do
      expect(subject).to receive_messages(:side_effect! => nil)
      subject.stupid_ivar = "hi"
      expect(subject.stupid_ivar).to eq("hi")
    end
  end

  context "when given an :aad option" do

    let(:cipher){ Slosilo::EncryptedAttributes.cipher }
    let(:key){ Slosilo::EncryptedAttributes.key}
    context "that is a string" do
      let(:aad){ "hello there" }
      before{ sub.attr_encrypted :with_aad, aad: aad }
      it "encrypts the value with the given string  for auth data" do
        expect(cipher).to receive(:encrypt).with("hello", key: key, aad: aad)
        subject.with_aad = "hello"
      end

      it "decrypts the encrypted value" do
        subject.with_aad = "foo"
        expect(subject.with_aad).to eq("foo")
      end
    end

    context "that is nil" do
      let(:aad){ nil }
      before{ sub.attr_encrypted :with_aad, aad: aad }
      it "encrypts the value with an empty string for auth data" do
        expect(cipher).to receive(:encrypt).with("hello",key: key, aad: "").and_call_original
        subject.with_aad = "hello"
      end

      it "decrypts the encrypted value" do
        subject.with_aad = "hello"
        expect(subject.with_aad).to eq("hello")
      end
    end

    context "that is a proc" do
      let(:aad){
        proc{ |o| "x" }
      }

      before{ sub.attr_encrypted :with_aad, aad: aad }

      it "calls the proc with the object being encrypted" do
        expect(aad).to receive(:[]).with(subject).and_call_original
        subject.with_aad = "hi"
      end

      it "encrypts the value with the string returned for auth data" do
        expect(cipher).to receive(:encrypt).with("hello", key: key, aad: aad[subject]).and_call_original
        subject.with_aad = "hello"
      end
      it "decrypts the encrypted value" do
        subject.with_aad = "hello"
        expect(subject.with_aad).to eq("hello")
      end
    end

  end


end
