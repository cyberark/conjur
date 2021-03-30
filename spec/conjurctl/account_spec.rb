require 'spec_helper'
require 'open3'

describe "account" do
  def delete_account(name)
    system("conjurctl account delete #{name}")
  end

  it "no account name provided" do
    _, stderr_str, = Open3.capture3(
      "conjurctl account create"
    )
    expect(stderr_str).to include("No account name was provided")
  end

  context "create with name demo" do
    after(:each) do
      delete_account("demo")
    end
    
    let(:password) { "MySecretP@SS1" }
    let(:create_account_with_password_and_name_flag) do
      "conjurctl account create --name demo --password-from-stdin"
    end

    let(:create_account_with_password_flag) do
      "conjurctl account create --password-from-stdin demo"
    end

    it "with no flags" do
      stdout_str, = Open3.capture3("conjurctl account create demo")
      expect(stdout_str).to include("API key for admin")
      expect(Slosilo["authn:demo"]).to be
      expect(Role["demo:user:admin"]).to be
    end

    it "with the name flag" do
      stdout_str, = Open3.capture3("conjurctl account create --name demo")
      expect(stdout_str).to include("API key for admin")
      expect(Slosilo["authn:demo"]).to be
      expect(Role["demo:user:admin"]).to be
    end

    it "with predefined password MySecretP@SS1 and account name flag" do
      stdout_str, = Open3.capture3(
        create_account_with_password_and_name_flag, stdin_data: password
      )
      expect(stdout_str).to include("Password is set")
      expect(Slosilo["authn:demo"]).to be
      expect(Role["demo:user:admin"]).to be
    end

    it "with predefined password MySecretP@SS1" do
      stdout_str, = Open3.capture3(
        create_account_with_password_flag, stdin_data: password
      )
      expect(stdout_str).to include("Password is set")
      expect(Slosilo["authn:demo"]).to be
      expect(Role["demo:user:admin"]).to be
    end

    it "with both an account name argument and flag" do
      system(
        "conjurctl account create --name demo ingored_account_name"
      )
      expect(Slosilo["authn:demo"]).to be
      expect(Role["demo:user:admin"]).to be
    end

    it "and with invalid password" do
      _, stderr_str, = Open3.capture3(
        create_account_with_password_flag, stdin_data: "invalid"
      )
      expect(stderr_str).to include("CONJ00046E")
      expect(Slosilo["authn:demo"]).not_to be
      expect(Role["demo:user:admin"]).not_to be
    end
  end
end
