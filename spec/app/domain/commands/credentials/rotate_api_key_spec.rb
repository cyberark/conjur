require 'spec_helper'

describe Commands::Credentials::RotateApiKey do
  let(:credentials) { double(Credentials) }
  let(:role) { double(Role, credentials: credentials) }

  let(:err_message) { 'the error message' }

  subject do 
    Commands::Credentials::RotateApiKey.new
  end

  it 'updates the password for the given User' do
    # Expect it to rotate the api key on the credentials model, and to save it
    expect(credentials).to receive(:rotate_api_key)
    expect(credentials).to receive(:save)

    # Call the command
    subject.call(role: role)
  end

  it 'bubbles up exceptions' do 
    # Assume the database update fails. This could be caused by an
    # invalid password, database issues, etc.
    allow(credentials).to receive(:rotate_api_key)
    allow(credentials).to receive(:save).and_raise(err_message)

    # Expect the command to raise the original exception
    expect { subject.call(role: role) }.to raise_error(err_message)
  end
end
