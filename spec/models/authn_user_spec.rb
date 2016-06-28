require 'spec_helper'

describe AuthnUser, :type => :model do
  let(:login) { "u-#{SecureRandom.uuid}"  }
  let(:password) { "password" }
  let(:user) { AuthnUser.new(login: login, password: password) }
  context "a user" do
    subject { user }
    it { is_expected.to be_valid }

    describe '#api_key' do
      subject { super().api_key }
      it { is_expected.to be_blank }
    end
    
    describe "#roleid" do
      it {
        expect(ENV).to receive(:[]).with("CONJUR_ACCOUNT").and_return "test"
        expect(user.roleid).to eq("test:user:#{login}")
      }
    end

    describe '#encrypted_hash' do
      subject { super().encrypted_hash }
      it { is_expected.not_to be_blank }
    end
    
    describe '#login' do
      subject { super().login }
      it { is_expected.to eq(login) }
    end
    
    it "should store encrypted password hash" do
      expect(BCrypt::Password::new(user.encrypted_hash)).to eq(password)
      expect(Slosilo::EncryptedAttributes.decrypt(user.values[:encrypted_hash], aad: login)).to eq(user.encrypted_hash)
    end
    
    context "saved" do
      before { user.save }

      describe "#as_json" do
        it "displays login" do
          expect(user.as_json).to eq({login: login})
        end
      end

      describe '#api_key' do
        subject { super().api_key }
        it { is_expected.not_to be_blank }
      end
      
      describe "#rotate_api_key" do
        it "changes the API key" do
          api_key = user.api_key
          user.rotate_api_key
          expect(user.api_key).to_not eq(api_key)
        end
      end
    end
    
    describe '#password=' do
      it 'sets no password when given nil' do
        user.password = nil
        user.save
        expect(user.authenticate password).to be_falsey
        expect(user.authenticate nil).to be_falsey
      end
      it 'disallows passwords with newlines' do
        user.password = "foo\nbar"
        user.save.should be_falsey
        user.errors.keys.should include(:password)
        user.errors[:password].should == [ "cannot contain a newline" ]
      end
    end
  end
  
  describe "#authenticate" do
    before { user.save }
    it "returns true on good password" do
      expect(user.authenticate password).to be_truthy
    end
    
    it "refreshes the hash to use new cost if good password is given" do
      user.encrypted_hash = BCrypt::Password.create(password)
      user.save
      user.reload
      expect(BCrypt::Password.new(user.encrypted_hash).cost).to eq(10)
      expect(user.authenticate password).to be_truthy
      user.reload
      expect(BCrypt::Password.new(user.encrypted_hash).cost).to eq(AuthnUser::BCRYPT_COST)
      expect(user.authenticate password).to be_truthy
    end

    it "returns true on good api key" do
      expect(user.authenticate user.api_key).to be_truthy
    end

    it "returns false otherwise" do
      expect(user.authenticate "backdoor").to be_falsey
    end
    
    it "returns false on nil" do
      expect(user.authenticate nil).to be_falsey
    end
    
    it "returns false on empty string" do
      expect(user.authenticate "").to be_falsey
    end
  end
end
