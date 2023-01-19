require 'spec_helper'

describe Commands::Credentials::RotateApiKey do
  let(:credentials) { double(Credentials) }
  let(:role) { double(Role, id: 'role', credentials: credentials) }

  let(:other_credentials) { double(Credentials) }
  let(:other_role) { double(Role, id: 'other role', credentials: other_credentials) }

  let(:client_ip) { 'my-client-ip' }

  let(:role_to_rotate) { role }

  let(:err_message) { 'the error message' }

  let(:audit_log) { double(::Audit.logger) }

  let(:audit_success) do
    ::Audit::Event::ApiKey.new(
      authenticated_role_id: role.id,
      rotated_role_id: role_to_rotate.id,
      client_ip: client_ip,
      success: true
    )
  end

  let(:audit_failure) do
    ::Audit::Event::ApiKey.new(
      authenticated_role_id: role.id,
      rotated_role_id: role_to_rotate.id,
      client_ip: client_ip,
      success: false,
      error_message: err_message
    )
  end

  subject do 
    Commands::Credentials::RotateApiKey.new(
      audit_log: audit_log
    )
  end

  context 'when rotating own API key' do
    it 'updates the key' do
      # Normally command inputs should not be mocked, however to seperate
      # the role "value" from the rotation and database operations would require
      # refactoring the Credentials controller. So the correct solution is out
      # of scope.
      expect(credentials).to receive(:rotate_api_key)
      expect(credentials).to receive(:save)

      # Expect it to log a successful audit message
      expect(audit_log).to receive(:log).with(audit_success)

      # Call the command
      subject.call(
        role_to_rotate: role, 
        authenticated_role: role, 
        client_ip: client_ip
      )
    end

    it 'bubbles up exceptions' do 
      # See note above. The command inputs should not typicially be mocked.
      # However, the refactoring to support the correct solution is
      # out of scope.
      #
      # Assume the database update fails. This could be caused by an
      # invalid password, database issues, etc.
      allow(credentials).to receive(:rotate_api_key)
      allow(credentials).to receive(:save).and_raise(err_message)

      # Expect it to log a failed audit message
      expect(audit_log).to receive(:log).with(audit_failure)

      # Expect the command to raise the original exception
      expect do
        subject.call(
          role_to_rotate: role,
          authenticated_role: role,
          client_ip: client_ip
        )
      end.to raise_error(err_message)
    end
  end

  context "when rotating another's API key" do
    let(:role_to_rotate) { other_role }

    it 'updates the key' do
      # Expect it to rotate the api key on the credentials model, and to save it
      expect(other_credentials).to receive(:rotate_api_key)
      expect(other_credentials).to receive(:save)

      # Expect it to log a successful audit message
      expect(audit_log).to receive(:log).with(audit_success)

      # Call the command
      subject.call(
        role_to_rotate: other_role,
        authenticated_role: role,
        client_ip: client_ip
      )
    end

    it 'bubbles up exceptions' do 
      # Assume the database update fails. This could be caused by an
      # invalid password, database issues, etc.
      allow(other_credentials).to receive(:rotate_api_key)
      allow(other_credentials).to receive(:save).and_raise(err_message)

      # Expect it to log a failed audit message
      expect(audit_log).to receive(:log).with(audit_failure)

      # Expect the command to raise the original exception
      expect do
        subject.call(
          role_to_rotate: other_role,
          authenticated_role: role,
          client_ip: client_ip
        )
      end.to raise_error(err_message)
    end
  end
end
