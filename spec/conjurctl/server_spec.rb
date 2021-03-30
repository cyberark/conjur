require 'spec_helper'
require 'open3'

describe "conjurctl server" do
  def delete_account(name)
    system("conjurctl account delete #{name}")
  end

  # Wait for conjur server to be up. 
  # Exit if it takes longer than 35 seconds
  def wait_for_conjur
    system("conjurctl wait --retries 35")
  end

  context "start server" do
    after(:each) do
      delete_account("demo")
      # Kills the conjur server process if it was started
      `/src/conjur-server/dev/files/killConjurServer`
    end

    it "with password-from-stdin flag but no account flag" do
      _, stderr_str, = Open3.capture3(
        "conjurctl server --password-from-stdin"
      )
      expect(stderr_str).to include("account is required")
      wait_for_conjur
      expect(Slosilo["authn:demo"]).not_to be
      expect(Role["demo:user:admin"]).not_to be
    end

    it "with account flag" do
      # Run in background to easily kill process later
      system("conjurctl server --account demo &")
      wait_for_conjur
      expect(Slosilo["authn:demo"]).to be
      expect(Role["demo:user:admin"]).to be
    end

    it "with both account and password-from-stdin flags" do
      # Run in background to easily kill process later
      system("
        echo -n 'MySecretP@SS1' | 
        conjurctl server --account demo --password-from-stdin &
      ")
      wait_for_conjur
      expect(Slosilo["authn:demo"]).to be
      expect(Role["demo:user:admin"]).to be
    end
  end
end
