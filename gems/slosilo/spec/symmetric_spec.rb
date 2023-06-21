require 'spec_helper'

describe Slosilo::Symmetric do
  # TODO transform it to class methods only?
  let(:plaintext) { "quick brown fox jumped over the lazy dog" }
  let(:auth_data) { "some record id" }
  let(:key) { "^\xBAIv\xDB1\x0Fi\x04\x11\xFD\x14\xA7\xCD\xDFf\x93\xFE\x93}\v\x01\x11\x98\x14\xE0;\xC1\xE2 v\xA5".force_encoding("ASCII-8BIT") }
  let(:iv) { "\xD9\xABn\x01b\xFA\xBD\xC2\xE5\xEA\x01\xAC".force_encoding("ASCII-8BIT") }
  let(:ciphertext) { "G^W1\x9C\xD4\xCC\x87\xD3\xFF\x86[\x0E3\xC0\xC8^\xD9\xABn\x01b\xFA\xBD\xC2\xE5\xEA\x01\xAC\x9E\xB9:\xF7\xD4ebeq\xDC \xC0sG\xA4\xAE,\xB8A|\x97\xBC\xFD\x85\xE1\xB93\x95>\xBD\n\x05\xFB\x15\x1F\x06#3M9".force_encoding('ASCII-8BIT') }

  describe '#encrypt' do
    it "encrypts with AES-256-GCM" do
      allow(subject).to receive_messages random_iv: iv
      expect(subject.encrypt(plaintext, key: key, aad: auth_data)).to eq(ciphertext)
    end
  end

  describe '#decrypt' do

    it "doesn't fail when called by multiple threads" do
      threads = []

      begin
        # Verify we can successfuly decrypt using many threads without OpenSSL
        # errors.
        1000.times do
          threads << Thread.new do
            100.times do
              expect(
                subject.decrypt(ciphertext, key: key, aad: auth_data)
              ).to eq(plaintext)
            end
          end
        end
      ensure
        threads.each(&:join)
      end
    end

    it "decrypts with AES-256-GCM" do
      expect(subject.decrypt(ciphertext, key: key, aad: auth_data)).to eq(plaintext)
    end


    context "when the ciphertext has been messed with" do
      let(:ciphertext) {  "pwnd!" } # maybe we should do something more realistic like add some padding?
      it "raises an exception" do
        expect{ subject.decrypt(ciphertext, key: key, aad: auth_data)}.to raise_exception /Invalid version/
      end
      context "by adding a trailing 0" do
        let(:new_ciphertext){ ciphertext + '\0' }
        it "raises an exception" do
          expect{ subject.decrypt(new_ciphertext, key: key, aad: auth_data) }.to raise_exception /Invalid version/
        end
      end
    end

    context "when no auth_data is given" do
      let(:auth_data){""}
      let(:ciphertext){ "Gm\xDAT\xE8I\x9F\xB7\xDC\xBB\x84\xD3Q#\x1F\xF4\x8C\aV\x93\x8F_\xC7\xBC87\xC9U\xF1\xAF\x8A\xD62\x1C5H\x86\x17\x19=B~Y*\xBC\x9D\eJeTx\x1F\x02l\t\t\xD3e\xA4\x11\x13y*\x95\x9F\xCD\xC4@\x9C"}

      it "decrypts the message" do
        expect(subject.decrypt(ciphertext, key: key, aad: auth_data)).to eq(plaintext)
      end

      context "and the ciphertext has been messed with" do
        it "raises an exception" do
          expect{ subject.decrypt(ciphertext + "\0\0\0", key: key, aad: auth_data)}.to raise_exception OpenSSL::Cipher::CipherError
        end
      end
    end

    context "when the auth data doesn't match" do
      let(:auth_data){ "asdf" }
      it "raises an exception" do
        expect{ subject.decrypt(ciphertext, key: key, aad: auth_data)}.to raise_exception OpenSSL::Cipher::CipherError
      end
    end
  end

  describe '#random_iv' do
    it "generates a random iv" do
      expect_any_instance_of(OpenSSL::Cipher).to receive(:random_iv).and_return :iv
      expect(subject.random_iv).to eq(:iv)
    end
  end

  describe '#random_key' do
    it "generates a random key" do
      expect_any_instance_of(OpenSSL::Cipher).to receive(:random_key).and_return :key
      expect(subject.random_key).to eq(:key)
    end
  end
end
