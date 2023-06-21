require 'spec_helper'
describe "Slosilo key" do
  before(:all) {
    init_slosilo_keys("rspec")
  }
  context "Update existing key" do
    it "possible to update existing key" do
      new_key = Slosilo::Key.new
      Slosilo["authn:rspec:host:current"] = new_key
      current_key = Slosilo["authn:rspec:host:current"]
      expect(current_key.to_der).to eq(new_key.to_der)
      expect(current_key.fingerprint).to eq(new_key.fingerprint)
    end
  end
end
