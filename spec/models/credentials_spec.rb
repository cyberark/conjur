# frozen_string_literal: true

require 'spec_helper'

describe Credentials, :type => :model do
  include_context "create user"

  let(:login) { "u-#{random_hex}" }
  let(:credentials) { the_user.credentials }
  
  context "a user" do
    subject { the_user }
    it { is_expected.to be_valid }

    describe "#roleid" do
      it {
        expect(credentials.role.role_id).to eq("rspec:user:#{login}")
      }
    end

    describe '#encrypted_hash' do
      subject { the_user.credentials.encrypted_hash }
      context "when password is specified" do
        let(:password) { "The-Password1" }
        it { is_expected.not_to be_blank }
      end
      context "when password is not specified" do
        it { is_expected.to be_blank }
      end
    end
    
    it "should store encrypted password hash" do
      expect(Slosilo::EncryptedAttributes.decrypt(credentials.values[:encrypted_hash], aad: the_user.role_id)).to eq(credentials.encrypted_hash)
    end

    describe '#api_key' do
      subject { the_user.credentials.api_key }
      it { is_expected.not_to be_blank }
    end
    
    describe "#rotate_api_key" do
      it "changes the API key" do
        api_key = credentials.api_key
        credentials.rotate_api_key
        expect(credentials.api_key).to_not eq(api_key)
      end
    end
    
    describe '#password=' do
      let(:insufficient_msg) { ::Errors::Conjur::InsufficientPasswordComplexity.new.to_s }
      context "with password" do
        let(:password) { "The-Password1" }
        it 'sets no password when given nil' do
          credentials.password = nil
          credentials.save
          expect(credentials.authenticate(password)).to be_falsey
          expect(credentials.valid_password?(password)).to be_falsey
          expect(credentials.valid_password?(nil)).to be_falsey
        end
      end
      it 'allows passwords with 128 characters long' do
        credentials.password = "My Password134567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678"
        expect { credentials.save }.not_to raise_error
      end
      it 'allows passwords with all acceptable special characters' do
        credentials.password = "New-Password1 !\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~]"
        expect { credentials.save }.not_to raise_error
      end
      it 'allows passwords with mixed languages (Russian and French)' do
        credentials.password = "New!Password1БбИиàâæ"
        expect { credentials.save }.not_to raise_error
      end
      it 'disallows passwords with newlines' do
        credentials.password = "My-\nPasswor1"
        expect { credentials.save }.to raise_error(Sequel::ValidationFailed) do |e|
          expect(e.errors.to_h).to eq({ password: [ insufficient_msg ]})
        end
      end
      it 'disallows passwords with 11 characters long' do
        credentials.password = "My-Passwor1"
        expect { credentials.save }.to raise_error(Sequel::ValidationFailed) do |e|
          expect(e.errors.to_h).to eq({ password: [ insufficient_msg ]})
        end
      end
      it 'disallows passwords with 129 characters long' do
        credentials.password = "My-Password1345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
        expect { credentials.save }.to raise_error(Sequel::ValidationFailed) do |e|
          expect(e.errors.to_h).to eq({ password: [ insufficient_msg ]})
        end
      end
      it 'disallows passwords with only 1 upper case character' do
        credentials.password = "My-password12"
        expect { credentials.save }.to raise_error(Sequel::ValidationFailed) do |e|
          expect(e.errors.to_h).to eq({ password: [ insufficient_msg ]})
        end
      end
      it 'disallows passwords with only 1 lower case character' do
        credentials.password = "My-P12345671"
        expect { credentials.save }.to raise_error(Sequel::ValidationFailed) do |e|
          expect(e.errors.to_h).to eq({ password: [ insufficient_msg ]})
        end
      end
      it 'disallows passwords without a digit' do
        credentials.password = "My-Passworda"
        expect { credentials.save }.to raise_error(Sequel::ValidationFailed) do |e|
          expect(e.errors.to_h).to eq({ password: [ insufficient_msg ]})
        end
      end
      it 'disallows passwords without a special character' do
        credentials.password = "NewPassword1"
        expect { credentials.save }.to raise_error(Sequel::ValidationFailed) do |e|
          expect(e.errors.to_h).to eq({ password: [ insufficient_msg ]})
        end
      end
      it 'disallows passwords with non supported special character' do
        credentials.password = "New¶Password1"
        expect { credentials.save }.to raise_error(Sequel::ValidationFailed) do |e|
          expect(e.errors.to_h).to eq({ password: [ insufficient_msg ]})
        end
      end
      it 'disallows passwords with empty password' do
        credentials.password = ""
        expect { credentials.save }.to raise_error(Sequel::ValidationFailed) do |e|
          expect(e.errors.to_h).to eq({ password: [ insufficient_msg ]})
        end
      end
    end
  end
  
  describe "authenticate" do
    before { credentials.save }
    context "with password" do
      let(:password) { "The-Password1" }
      it "returns true on good password" do
        expect(credentials.authenticate(password)).to be_truthy
        expect(credentials.valid_password?(password)).to be_truthy
      end
    end

    describe "role without api key" do
      before {
        credentials.api_key = nil
        credentials.save
      }
      it "doesn't have a valid API key" do
        expect(credentials.valid_api_key?("")).to be(false)
      end
    end

    describe "with expiration" do
      let(:now) { Time.now }
      let(:past) { now - 1.second }
      let(:future) { now + 1.second }
      describe "with API key" do
        before {
          expect(Time).to receive(:now).at_least(1).and_return(now)
          credentials.expiration = expiration_time
          credentials.save
        }
        describe "when unexpired" do
          let(:expiration_time) { future }
          it "has a valid API key" do
            expect(credentials.valid_api_key?(credentials.api_key)).to be(true)
          end
        end
        describe "when expired" do
          let(:expiration_time) { past }
          it "has an invalid API key" do
            expect(credentials.valid_api_key?(credentials.api_key)).to be(false)
          end
        end
      end
      context "with password" do
        let(:password) { "The-Password1" }
        describe "when expired" do
          let(:expiration_time) { past }
          it "has a valid password" do
            expect(credentials.valid_password?(password)).to be_truthy
          end
          it "authenticates" do
            expect(credentials.authenticate(password)).to be_truthy
          end
        end
      end
    end

    it "returns true on good api key" do
      expect(credentials.authenticate(credentials.api_key)).to be_truthy
    end

    it "returns false otherwise" do
      expect(credentials.authenticate("backdoor")).to be_falsey
    end
    
    it "returns false on nil" do
      expect(credentials.authenticate(nil)).to be_falsey
    end
    
    it "returns false on empty string" do
      expect(credentials.authenticate("")).to be_falsey
    end
  end
end
