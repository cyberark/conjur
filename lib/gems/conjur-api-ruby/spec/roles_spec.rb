require 'spec_helper'

describe Conjur::API do
  describe '#role_name_from_username' do
    let(:account) { "the-account" }
    context "when username is" do
      [
        [ 'the-user', 'the-account:user:the-user' ],
        [ 'host/the-host', 'the-account:host:the-host' ],
        [ 'host/a/quite/long/host/name', 'the-account:host:a/quite/long/host/name' ],
        [ 'newkind/host/name', 'the-account:newkind:host/name' ],
      ].each do |p|
        context "'#{p[0]}'" do
          let(:username) { p[0] }

          describe '#role_name_from_username' do
            subject { Conjur::API.role_name_from_username username, account }
            it { is_expected.to eq(p[1]) }
          end
        end
      end
    end
  end
end
