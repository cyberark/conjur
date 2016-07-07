require 'spec_helper'

describe Credentials, :type => :model do
  include_context "create user"

  let(:login) { "u-#{SecureRandom.uuid}" }
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
        let(:password) { "the-password" }
        it { is_expected.not_to be_blank }
      end
      context "when password is not specified" do
        it { is_expected.to be_blank }
      end
    end
    
    describe '#login' do
      subject { the_user.login }
      it { is_expected.to eq(login) }
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
      context "with password" do
        let(:password) { "the-password" }
        it 'sets no password when given nil' do
          credentials.password = nil
          credentials.save
          expect(credentials.authenticate password).to be_falsey
          expect(credentials.authenticate nil).to be_falsey
        end
      end
      it 'disallows passwords with newlines' do
        credentials.password = "foo\nbar"
        credentials.save.should be_falsey
        credentials.errors.keys.should include(:password)
        credentials.errors[:password].should == [ "cannot contain a newline" ]
      end
    end
  end
  
  describe "#authenticate" do
    before { credentials.save }
    context "with password" do
      let(:password) { "the-password" }
      it "returns true on good password" do
        expect(credentials.authenticate password).to be_truthy
      end
    end
    
    it "returns true on good api key" do
      expect(credentials.authenticate credentials.api_key).to be_truthy
    end

    it "returns false otherwise" do
      expect(credentials.authenticate "backdoor").to be_falsey
    end
    
    it "returns false on nil" do
      expect(credentials.authenticate nil).to be_falsey
    end
    
    it "returns false on empty string" do
      expect(credentials.authenticate "").to be_falsey
    end
  end
end
