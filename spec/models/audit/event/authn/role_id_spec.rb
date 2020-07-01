require 'spec_helper'

describe ::Audit::Event::Authn::RoleId do
  let(:role_id) { 'some:role:id' }
  let(:role) { double('Role', id: role_id) }

  it 'returns role.id when role is provided' do
    subj = Audit::Event::Authn::RoleId.new(
      role: role, account: nil, username: nil
    )
    expect(subj.to_s).to eq(role_id)
  end

  it 'constructs "role id" from account/username when role is missing' do
    subj = ::Audit::Event::Authn::RoleId.new(
      role: nil, account: 'my_account', username: 'my_username'
    )
    expect(subj.to_s).to eq('my_account:user:my_username')
  end

  it 'constructs a placeholder "role id" when account is missing' do
    subj = ::Audit::Event::Authn::RoleId.new(
      role: nil, account: nil, username: 'my_username'
    )
    placeholder = ::Audit::Event::Authn::RoleId::ACCOUNT_PLACEHOLDER
    expect(subj.to_s).to eq("#{placeholder}:user:my_username")
  end

  it 'constructs a placeholder "role id" when username is missing' do
    subj = ::Audit::Event::Authn::RoleId.new(
      role: nil, account: 'my_account', username: nil
    )
    placeholder = ::Audit::Event::Authn::RoleId::USERNAME_PLACEHOLDER
    expect(subj.to_s).to eq("my_account:user:#{placeholder}")
  end
end

