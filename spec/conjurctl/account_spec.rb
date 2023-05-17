require 'spec_helper'
require 'open3'

def delete_account(name)
  system("conjurctl account delete #{name}")
end

def create_default_account()
  system("conjurctl account create")
end

describe "account" do
  it "creates default account when no name provided" do
    stdout_str, = Open3.capture3(
      "conjurctl account create"
    )
    expect(stdout_str).to include("API key for admin")
    expect(token_key("default", "host")).to be
    expect(token_key("default", "user")).to be
    expect(Role["default:user:admin"]).to be
    expect(Credentials["default:user:admin"]).to be
    delete_account("default")
  end

  it "delete account" do
    create_default_account()
    delete_account("default")
    expect(token_key("default", "host")).not_to be
    expect(token_key("default", "user")).not_to be
    expect(Role["default:user:admin"]).not_to be
    expect(Credentials["default:user:admin"]).not_to be
  end

  context "create with name demo" do
    after(:each) do
      delete_account("demo")
    end

    let(:password) { "MySecretP,@SS1()!" }
    let(:create_account_with_password_and_name_flag) do
      "conjurctl account create --name demo --password-from-stdin"
    end

    let(:create_account_with_password_flag) do
      "conjurctl account create --password-from-stdin demo"
    end

    it "with no flags" do
      stdout_str, = Open3.capture3("conjurctl account create demo")
      expect(stdout_str).to include("API key for admin")
      expect(token_key("demo", "host")).to be
      expect(token_key("demo", "user")).to be
      expect(Role["demo:user:admin"]).to be
      expect(Credentials["demo:user:admin"]).to be
    end

    it "with the name flag" do
      stdout_str, = Open3.capture3("conjurctl account create --name demo")
      expect(stdout_str).to include("API key for admin")
      expect(token_key("demo", "host")).to be
      expect(token_key("demo", "user")).to be
      expect(Role["demo:user:admin"]).to be
      expect(Credentials["demo:user:admin"]).to be
    end

    it "with predefined password and account name flag" do
      stdout_str, = Open3.capture3(
        create_account_with_password_and_name_flag, stdin_data: password
      )
      expect(stdout_str).to include("Password is set")
      expect(token_key("demo", "host")).to be
      expect(token_key("demo", "user")).to be
      expect(Role["demo:user:admin"]).to be
      expect(Credentials["demo:user:admin"]).to be
    end

    it "with predefined password" do
      stdout_str, = Open3.capture3(
        create_account_with_password_flag, stdin_data: password
      )
      expect(stdout_str).to include("Password is set")
      expect(token_key("demo", "host")).to be
      expect(token_key("demo", "user")).to be
      expect(Role["demo:user:admin"]).to be
      expect(Credentials["demo:user:admin"]).to be
    end

    it "with both an account name argument and flag" do
      system(
        "conjurctl account create --name demo ingored_account_name"
      )
      expect(token_key("demo", "host")).to be
      expect(token_key("demo", "user")).to be
      expect(Role["demo:user:admin"]).to be
      expect(Credentials["demo:user:admin"]).to be
    end

    it "and with invalid password" do
      _, stderr_str, = Open3.capture3(
        create_account_with_password_flag, stdin_data: "invalid"
      )
      expect(stderr_str).to include("CONJ00046E")
      expect(token_key("demo", "host")).not_to be
      expect(token_key("demo", "user")).not_to be
      expect(Role["demo:user:admin"]).not_to be
      expect(Credentials["demo:user:admin"]).not_to be
    end
  end
end
