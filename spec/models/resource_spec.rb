require 'spec_helper'

describe Resource, :type => :model do
  include_context "create user"
  
  let(:login) { "u-#{SecureRandom.uuid}" }
  let(:the_resource) { Resource.create(resource_id: the_user.role_id, owner: the_user) }

  shared_examples_for "provides expected JSON" do
    specify {
      the_resource.reload
      hash = JSON.parse(the_resource.to_json)
      expect(hash.delete("created_at")).to be
      expect(hash).to eq(as_json.stringify_keys)
    }
  end
  
  let(:base_hash) {
    {
      id: the_resource.resource_id,
      owner: the_user.role_id,
      permissions: [],
      annotations: [],
      secrets: []
    }
  }
  
  it "account is required" do
    expect{ Resource.create(resource_id: "", owner: the_user) }.to raise_error(Sequel::CheckConstraintViolation, /(has_kind|has_account)/)
  end
  it "kind is required" do
    expect{ Resource.create(resource_id: "the-account", owner: the_user) }.to raise_error(Sequel::CheckConstraintViolation, /has_kind/)
  end
    
  context "basic object" do
    let(:as_json) { base_hash }
    it_should_behave_like "provides expected JSON"
  end
  
  context "with annotation" do
    before {
      Annotation.create resource: the_resource, name: "name", value: "Kevin"
    }
    let(:as_json) { 
      base_hash.merge annotations: [ { "name" => "name", "value" => "Kevin" } ]
    }
    it_should_behave_like "provides expected JSON"
  end
  context "with permission" do
    before {
      the_resource.permit "fry", the_user
    }
    let(:as_json) { 
      base_hash.merge permissions: [ {"privilege"=>"fry", "grant_option"=>false, "role"=>the_user.id, "grantor"=>the_user.id} ]
    }
    it_should_behave_like "provides expected JSON"
  end
  context "with secret" do
    before {
      the_resource.add_secret value: "the-value"
    }
    let(:as_json) { 
      base_hash.merge secrets: [ {"counter" => 1} ]
    }
    it_should_behave_like "provides expected JSON"
  end

  describe "#enforce_secrets_version_limit" do
    it "deletes extra secrets" do
      the_resource.add_secret value: "v-1"
      the_resource.add_secret value: "v-2"
      the_resource.add_secret value: "v-3"
      expect(the_resource.as_json['secrets']).to eq([ 1, 2, 3 ].map{|i| { "counter" => i }})

      the_resource.enforce_secrets_version_limit 2
      the_resource.reload

      expect(the_resource.as_json['secrets']).to eq([ 2, 3 ].map{|i| { "counter" => i }})

      the_resource.enforce_secrets_version_limit 1
      the_resource.reload

      expect(the_resource.as_json['secrets']).to eq([ 3 ].map{|i| { "counter" => i }})
    end
  end
end
