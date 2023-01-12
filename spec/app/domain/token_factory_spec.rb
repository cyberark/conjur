# frozen_string_literal: true

require 'spec_helper'

describe TokenFactory  do
  before(:all) { Slosilo["authn:cucumber"] ||= Slosilo::Key.new }
  let(:token_factory) { TokenFactory.new }
  let(:ttl_limit) { 5 * 60 * 60 } # five hours
  let(:ttl_minimum) { 30 } # 30 seconds

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
    context 'when ttl is less than minimum allowed' do
      it 'returns minimum' do
        offset = 2
        expect(token_factory.offset(ttl: offset)).to eq(ttl_minimum)
      end
    end
  end

  describe '.get_ttl' do
    context 'when a ttl is provided' do
      context 'when ttl is an integer' do
        it 'returns the ttl' do
          expect(token_factory.get_ttl(ttl: 100, default_ttl: 200, is_host: false)).to eq(100)
        end
      end
      context 'when ttl is a float' do
        it 'returns the ttl' do
          expect(token_factory.get_ttl(ttl: 100.0, default_ttl: 200, is_host: false)).to eq(100)
        end
      end
      context 'when ttl is a string' do
        it 'returns the ttl' do
          expect(token_factory.get_ttl(ttl: '100', default_ttl: 200, is_host: false)).to eq(100)
        end
      end
      context 'when ttl is not an integer' do
        it 'returns the default ttl' do
          expect(token_factory.get_ttl(ttl: 'foo', default_ttl: 200, is_host: false)).to eq(200)
        end
      end
    end
    context 'when a user ttl is set using configuration' do
      let(:token_factory) { TokenFactory.new(default_user_ttl: 150) }
      context 'when ttl is present it takes precedence' do
        it 'returns the default ttl' do
          expect(token_factory.get_ttl(ttl: 100, default_ttl: 200, is_host: false)).to eq(100)
        end
      end
      context 'when ttl is not present' do
        it 'returns the configured ttl' do
          expect(token_factory.get_ttl(ttl: 0, default_ttl: 200, is_host: false)).to eq(150)
        end
      end
      context 'when configuration is a string' do
        let(:token_factory) { TokenFactory.new(default_user_ttl: '150') }
        it 'returns the configured ttl' do
          expect(token_factory.get_ttl(ttl: 0, default_ttl: 200, is_host: false)).to eq(150)
        end
      end
      context 'when configuration is not an integer' do
        let(:token_factory) { TokenFactory.new(default_user_ttl: 'foo') }
        it 'returns the configured ttl' do
          expect(token_factory.get_ttl(ttl: 0, default_ttl: 200, is_host: false)).to eq(200)
        end
      end
    end
    context 'when a host ttl is set using configuration' do
      let(:token_factory) { TokenFactory.new(default_host_ttl: 150) }
      context 'when ttl is present it takes precedence' do
        it 'returns the default ttl' do
          expect(token_factory.get_ttl(ttl: 100, default_ttl: 200, is_host: true)).to eq(100)
        end
      end
      context 'when ttl is not present' do
        it 'returns the configured ttl' do
          expect(token_factory.get_ttl(ttl: 0, default_ttl: 200, is_host: true)).to eq(150)
        end
      end
      context 'when configuration is a string' do
        let(:token_factory) { TokenFactory.new(default_host_ttl: '150') }
        it 'returns the configured ttl' do
          expect(token_factory.get_ttl(ttl: 0, default_ttl: 200, is_host: true)).to eq(150)
        end
      end
      context 'when configuration is not an integer' do
        let(:token_factory) { TokenFactory.new(default_host_ttl: 'foo') }
        it 'returns the configured ttl' do
          expect(token_factory.get_ttl(ttl: 0, default_ttl: 200, is_host: true)).to eq(200)
        end
      end
    end
    context 'when a user ttl is set using configuration' do
      let(:token_factory) { TokenFactory.new(default_user_ttl: 150) }
      context 'when ttl is present it takes precedence' do
        it 'returns the default ttl' do
          expect(token_factory.get_ttl(ttl: 100, default_ttl: 200, is_host: false)).to eq(100)
        end
      end
      context 'when ttl is not present' do
        it 'returns the configured ttl' do
          expect(token_factory.get_ttl(ttl: 0, default_ttl: 200, is_host: false)).to eq(150)
        end
      end
    end
    context 'when ttl is zero' do
      context 'when default is an integer' do
        it 'returns the default ttl' do
          expect(token_factory.get_ttl(ttl: 0, default_ttl: 200, is_host: false)).to eq(200)
        end
      end
      context 'when ttl is a float' do
        it 'returns the ttl' do
          expect(token_factory.get_ttl(ttl: 0, default_ttl: 200.0, is_host: false)).to eq(200)
        end
      end
      context 'when ttl is a string' do
        it 'returns the ttl' do
          expect(token_factory.get_ttl(ttl: 0, default_ttl: '200', is_host: false)).to eq(200)
        end
      end
      context 'when ttl is not an integer' do
        it 'returns the default ttl' do
          expect(token_factory.get_ttl(ttl: 0, default_ttl: 'foo', is_host: false)).to eq(0)
        end
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
      it 'uses the provided ttl' do
        freeze_time do
          token = token_factory.signed_token(account: "cucumber", username: "myuser", ttl: 60)
          expect(token.claims[:exp]).to eq((Time.now + 60).to_i)
        end
      end
      it 'uses the provided default ttl' do
        freeze_time do
          token = token_factory.signed_token(account: "cucumber", username: "host/myhost", default_ttl: 30)
          expect(token.claims[:exp]).to eq((Time.now + 30).to_i)
        end
      end
      context 'when configuration is set' do
        let(:token_factory) { TokenFactory.new(default_host_ttl: 150) }
        it 'uses the configured ttl' do
          freeze_time do
            token = token_factory.signed_token(account: "cucumber", username: "host/myhost", default_ttl: 30)
            expect(token.claims[:exp]).to eq((Time.now + 150).to_i)
          end
        end
      end
    end
    context 'when ttl exceeds limit' do
      it 'uses the ttl limit for user' do
        freeze_time do
          token = token_factory.signed_token(account: "cucumber", username: "myuser", ttl: ttl_limit + 1)
          expect(token.claims[:exp]).to eq((Time.now + ttl_limit).to_i)
        end
      end
      it 'uses the ttl limit for host' do
        freeze_time do
          token = token_factory.signed_token(account: "cucumber", username: "host/myhost", ttl: ttl_limit + 1)
          expect(token.claims[:exp]).to eq((Time.now + ttl_limit).to_i)
        end
      end
    end
  end
end
