require 'spec_helper'

RSpec.describe('Authentication::AuthnOidc::V2::Commands::ListProviders') do

  let(:issue_token)  do
    Commands::Authentication::IssueToken.new()
  end

  def create_account
    Account.create("test")
  end

  describe('#call') do
    context 'When you issue a token' do
      context 'When the account exists' do
        it 'returns the token' do
          create_account
          token = JSON.parse(issue_token.call(
            message: { account: 'test', sub: 'test', exp: "test", cidr: "test" }.to_json
          ))
          expect( token["protected"]).to be
        end
      end

      context 'When its a nonexistant account' do
        it 'returns a "no signing key found" error' do
          expect do
           issue_token.call(
              message: { account: 'bad-account', sub: 'test', exp: "test", cidr: "test" }.to_json
            )
          end.to raise_error('No signing key found for account "bad-account"')
        end
      end

      context 'When you dont send an account' do
        it 'raises an error to say account is required' do
          expect do
            issue_token.call(
              message: { sub: 'test' }.to_json
            )
          end.to raise_error("'account' is required")
        end
      end

      context 'When you dont send an sub' do
        it 'raises an error to say account is required' do
          expect do
            issue_token.call(
              message: { account: 'test', exp: "test", cidr: "test" }.to_json
            )
          end.to raise_error("'sub' is required")
        end
      end

      context 'When you dont send a message' do
        it 'raises an error to say account is required' do
          expect do
            issue_token.call(
            )
          end.to raise_error("missing keyword: :message")
        end
      end
    end
  end
end