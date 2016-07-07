require 'spec_helper'

describe Role, :type => :model do
  include_context "create user"

  let(:login) { "u-#{SecureRandom.uuid}" }

  it "provides expected JSON" do
    expect(JSON.parse(the_user.to_json)).to eq({
      uidnumber: nil,
      gidnumber: nil,
      id: the_user.role_id
    }.stringify_keys)
  end
end
