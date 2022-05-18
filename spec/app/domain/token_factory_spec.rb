# frozen_string_literal: true

require 'spec_helper'

describe TokenFactory  do

  before(:all) { Slosilo["authn:cucumber"] ||= Slosilo::Key.new }

  it "should generate a token for user with 8 minutes expiration" do
      Rails.application.config.conjur_config.user_authorization_token_ttl = 8.minutes
      Rails.application.config.conjur_config.host_authorization_token_ttl = 0
      token_expiration = Time.now + 8.minutes
      token_factory = TokenFactory.new
      token = token_factory.signed_token(account: "cucumber", username: "myuser")
      expect(token.claims[:exp]).to be >= token_expiration.to_i
      expect(token.claims[:exp]).to be < (Time.now + 8.minutes + 1.seconds).to_i
    end

    it "should generate a token for host with 8 minutes expiration" do
      Rails.application.config.conjur_config.user_authorization_token_ttl = 0
      Rails.application.config.conjur_config.host_authorization_token_ttl = 8.minutes
      token_expiration = Time.now + 8.minutes
      token_factory = TokenFactory.new
      token = token_factory.signed_token(account: "cucumber", username: "host/demo-host")
      expect(token.claims[:exp]).to be >= token_expiration.to_i
      expect(token.claims[:exp]).to be < (Time.now + 8.minutes + 1.seconds).to_i
    end

    it "should generate maximum token expiration for user" do
      Rails.application.config.conjur_config.user_authorization_token_ttl = 6.hours
      Rails.application.config.conjur_config.host_authorization_token_ttl = 0
      token_expiration = Time.now + 5.hours
      token_factory = TokenFactory.new
      token = token_factory.signed_token(account: "cucumber", username: "myuser")
      expect(token.claims[:exp]).to be >= token_expiration.to_i
      expect(token.claims[:exp]).to be < (Time.now + 5.hours + 1.second).to_i
    end

    it "should generate maximum token expiration for host" do
      Rails.application.config.conjur_config.user_authorization_token_ttl = 0
      Rails.application.config.conjur_config.host_authorization_token_ttl = 6.hours
      token_expiration = Time.now + 5.hours
      token_factory = TokenFactory.new
      token = token_factory.signed_token(account: "cucumber", username: "host/demo-host")
      expect(token.claims[:exp]).to be >= token_expiration.to_i
      expect(token.claims[:exp]).to be < (Time.now + 5.hours + 1.second).to_i
    end

end
