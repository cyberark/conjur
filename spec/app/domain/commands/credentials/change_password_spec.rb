require 'spec_helper'

describe Commands::Credentials::ChangePassword do
  let(:credentials) { double(Credentials) }
  let(:role) { double(Role, credentials: credentials) }
  let(:password) { 'the_password' }

  let(:err_message) { 'the error message' }

  subject do 
    Commands::Credentials::ChangePassword.new
  end

  it 'updates the password for the given User' do
    # Expect it to update the credentials model on the provided
    # role, with the given password
    expect(credentials).to receive(:password=).with(password)
    expect(credentials).to receive(:save)

    # Call the command
    subject.call(role: role,  password: password)
  end

  it 'bubbles up exceptions' do 
    # Assume the database update fails. This could be caused by an
    # invalid password, database issues, etc.
    allow(credentials).to receive(:password=)
    allow(credentials).to receive(:save).and_raise(err_message)

    # Expect the command to raise the original exception
    expect { subject.call(role: role,  password: password) }.to raise_error(err_message)
  end
end
