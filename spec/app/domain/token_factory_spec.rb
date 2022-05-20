# frozen_string_literal: true

require 'spec_helper'

describe TokenFactory  do

  before(:all) { Slosilo["authn:cucumber"] ||= Slosilo::Key.new }
  let(:token_factory) { TokenFactory.new }
  let(:ttl_limit) { 5 * 60 * 60 } # five hours

  describe '.offset' do
    context 'when ttl exceeds maximum allowed' do
      it 'returns maximum' do
        expect(token_factory.offset(ttl: 6 * 60 * 60)).to eq(ttl_limit)
      end
    end
    context 'when ttl is less than maximum allowed' do
      it 'returns ttl' do
        offset = 4 * 60 * 60
        expect(token_factory.offset(ttl: offset)).to eq(offset)
      end
    end
    context 'when ttl is invalid' do
      it 'returns zero' do
        expect(token_factory.offset(ttl: 'foo')).to eq(0)
      end
    end
  end

  describe '.signed_token' do
    context 'with default settings' do
      it 'uses the default user ttl' do
        freeze_time do
          token = token_factory.signed_token(account: "cucumber", username: "myuser")
          expect(token.claims[:exp]).to eq((Time.now + 8 * 60).to_i)
        end
      end
      it 'uses the default host ttl' do
        freeze_time do
          token = token_factory.signed_token(account: "cucumber", username: "host/myhost")
          expect(token.claims[:exp]).to eq((Time.now + 8 * 60).to_i)
        end
      end
    end
    context 'with custom settings' do
      it 'uses the provided user ttl' do
        freeze_time do
          token = token_factory.signed_token(account: "cucumber", username: "myuser", user_ttl: 60)
          expect(token.claims[:exp]).to eq((Time.now + 60).to_i)
        end
      end
      it 'uses the provided host ttl' do
        freeze_time do
          token = token_factory.signed_token(account: "cucumber", username: "host/myhost", host_ttl: 30)
          expect(token.claims[:exp]).to eq((Time.now + 30).to_i)
        end
      end
    end
    context 'when ttl exceeds limit' do
      it 'uses the ttl limit for user' do
        freeze_time do
          token = token_factory.signed_token(account: "cucumber", username: "myuser", user_ttl: ttl_limit + 1)
          expect(token.claims[:exp]).to eq((Time.now + ttl_limit).to_i)
        end
      end
      it 'uses the ttl limit for host' do
        freeze_time do
          token = token_factory.signed_token(account: "cucumber", username: "host/myhost", host_ttl: ttl_limit + 1)
          expect(token.claims[:exp]).to eq((Time.now + ttl_limit).to_i)
        end
      end
    end
  end
end
