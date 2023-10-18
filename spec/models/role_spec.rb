# frozen_string_literal: true

require 'spec_helper'

include Authentication::OptionalApiKey

describe Role, :type => :model do
  include_context "create user"

  let(:login) { "u-#{random_hex}" }

  shared_examples_for "provides expected JSON" do
    specify {
      the_user.reload
      hash = JSON.parse(the_user.to_json)
      expect(hash.delete("created_at")).to be
      expect(hash).to eq(as_json.stringify_keys)
    }
  end

  let(:base_hash) {
    {
      id: the_user.role_id
    }
  }

  it "account is required" do
    expect{ Role.create(role_id: "") }.to raise_error(Sequel::CheckConstraintViolation, /(has_kind|has_account)/)
  end
  it "kind is required" do
    expect{ Role.create(role_id: "the-account") }.to raise_error(Sequel::CheckConstraintViolation, /has_kind/)
  end

  context "basic object" do
    let(:as_json) { base_hash }
    it_should_behave_like "provides expected JSON"
  end

  it "can find by login" do
    expect(Role.by_login(login, account: 'rspec')).to eq(the_user)
  end

  context "Role has API key per annotation" do

    subject(:role) {  Role.create(role_id: "rspec:host:#{login}") }

    it "has API key when annotation is set to true" do
      allow(subject).to receive(:annotations).and_return([Annotation.new(name: AUTHN_ANNOTATION, value: "true")])
      expect(subject.api_key).to be_present
    end

    it "has API key when annotation is set to false" do
      allow(subject).to receive(:annotations).and_return([Annotation.new(name: AUTHN_ANNOTATION, value: "false")])
      expect(subject.api_key).to be_nil
    end

    it "has API key when annotation is set to blabla" do
      allow(subject).to receive(:annotations).and_return([Annotation.new(name: AUTHN_ANNOTATION, value: "blabla")])
      expect(subject.api_key).to be_nil
    end

    it "has API key when annotation is not set" do
      expect(subject.api_key).to be_nil
    end
  end
end
