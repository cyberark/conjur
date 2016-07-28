require 'spec_helper'

describe Secret, :type => :model do
  include_context "create user"
  
  let(:login) { "u-#{SecureRandom.uuid}" }
    
  describe "#latest_public_keys" do
    let(:key_name) { "the-key-name" }
    let(:resource) { Resource.create(resource_id: "rspec:public_key:user/alice/#{key_name}", owner: the_user) }
    
    it "finds only the latest public key of a user" do
      Secret.create resource: resource, value: "value-0"
      Secret.create resource: resource, value: "value-1"
      
      expect(Secret.latest_public_keys("rspec", "user", "alice")).to eq(["value-1"])
    end
  end
end
