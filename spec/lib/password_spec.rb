require 'spec_helper'

describe Conjur::Password do
  context "Password" do
    it "is valid" do
      expect(Conjur::Password.valid?("MySecretP@SS1")).to be(true)
    end

    context "is not valid because it is" do
      it "too short" do
        expect(Conjur::Password.valid?("SecretP@SS1")).to be(false)
      end
      it "missing a digit" do
        expect(Conjur::Password.valid?("MySecretP@SS")).to be(false)
      end
      it "missing a special character" do
        expect(Conjur::Password.valid?("MySecretPASS1")).to be(false)
      end
      it "missing atleast 2 uppercase letters" do
        expect(Conjur::Password.valid?("mySecretp@ss1")).to be(false)
        expect(Conjur::Password.valid?("mysecretp@ss1")).to be(false)
      end
      it "missing atleast 2 lowercase letters" do
        expect(Conjur::Password.valid?("MYSECRETP@Ss1")).to be(false)
        expect(Conjur::Password.valid?("MYSECRETP@SS1")).to be(false)
      end
      it "too long" do
        expect(Conjur::Password.valid?("MySecretP@SS1"*10)).to be(false)
      end
      it "is nil" do
        expect(Conjur::Password.valid?(nil)).to be(false)
      end
    end
  end
end
