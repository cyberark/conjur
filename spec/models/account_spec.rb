# frozen_string_literal: true

require 'spec_helper'

describe Account, :type => :model do
  let(:account_name) { "account-crud-rspec" }

  def create_account
    Account.create(account_name)
  end

  describe "account creation" do
    describe "when the account does not exist" do
      it "succeeds" do
        create_account

        expect(token_key(account_name, "host")).to be
        expect(token_key(account_name, "user")).to be
        admin = Role["#{account_name}:user:admin"]
        expect(admin).to be
        expect(admin.credentials).to be
      end
    end

    describe "when the account exists" do
      before { create_account }
      it "refuses" do
        expect { Account.create(account_name) }.to raise_error(Exceptions::RecordExists)
      end
      describe "and it refuses" do
        let!(:exception) do
          begin
            Account.create(account_name)
          rescue
            $!
          end
        end
        describe("its kind") { specify { expect(exception.kind).to eq("account") } }
        describe("its id")   { specify { expect(exception.id).to eq(account_name) } }
      end
    end
  end

  describe "account listing" do
    before {
      create_account
    }
    it "includes the new account" do
      expect(Account.list).to include(account_name)
    end

    it "does not include the special account !" do
      expect(Account.list).to_not include("!")
    end
  end

  describe "account deletion" do
    describe "when the account does not exist" do
      it "is not found" do
        expect { Account.new(account_name).delete }.to raise_error(Sequel::NoMatchingRow)
      end
      describe "and it refuses" do
        let!(:exception) do
          begin
            Account.new(account_name).delete
          rescue
            $!
          end
        end
        describe("its kind") { specify { expect(exception.dataset.model.table_name).to eq(:slosilo_keystore) } }
      end
    end

    describe "when the account exists" do
      it "deletes it" do
        create_account
        Account.new(account_name).delete 

        expect(token_key(account_name, "host")).to_not be
        expect(token_key(account_name, "user")).to_not be
        expect(Role["#{account_name}:user:admin"]).to_not be
      end
    end
  end
end
