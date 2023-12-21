# frozen_string_literal: true

require 'io/console'

namespace :role do
  desc "Reset the password and API key for the given role"
  task :"reset-password", [:role_id] => [:environment] do |_, args|
    # Disable deprecation warnings
    Dry::Core::Deprecations.set_logger!(File.open(File::NULL, "w"))

    # Ensure the Rails environment is loaded for audit support
    ENV['RAILS_ENV'] ||= 'appliance'
    require 'config/environment'

    # Load audit data model
    $LOAD_PATH << 'app/models'
    require 'audit'
    require 'audit/event'
    require 'audit/attempted_action'

    # For each failure, print an error explanation to stderr and a
    # blank line to stdout so that a script using conjurctl always
    # gets one line of output per role.
    # If stdout is a TTY, skip printing the blank line so it's not
    # confusing for humans.

    role = Role.first(role_id: args[:role_id])

    # Verify that the role exists
    unless role
      $stderr.puts("error: role does not exist: #{args[:role_id]}")
      puts unless $stdout.isatty
      exit(1)
    end

    # Verify the given role is a User and not a host, group, etc.
    unless role.kind == 'user'
      $stderr.puts(
        "error: only user passwords may be reset. " \
        "'#{args[:role_id]}' is a '#{role.kind}'."
      )
      puts unless $stdout.isatty
      exit(1)
    end

    password = IO::console.getpass("Enter new password: ")
    password_again = IO::console.getpass("Re-enter password: ")

    # Verify the same password was given each time
    unless password == password_again
      $stderr.puts("error: passwords do not match")
      puts unless $stdout.isatty
      exit(1)
    end

    # Verify the entered password matches the requirements
    unless Conjur::Password.valid?(password)
      $stderr.puts(Errors::Conjur::InsufficientPasswordComplexity.new.to_s)
      puts unless $stdout.isatty
      exit(1)
    end

    # Verify that the credential update happens as a single database transaction.
    # The password change and API key rotation operations should either succeed or fail
    # together.  For failure identification unique errors are reported for each operation.
    begin
      Role.db.transaction do
        begin
          # The ops indicate failure by exception
          change_password_wrapper(role, password)
          rotate_key_wrapper(role)
        rescue => e
          # Note the ops problem, then re-raise so that the transaction
          # is rolled back and db.transaction will re-raise the exception
          raise("failed in transaction: #{e.message}")
        end
      end
    rescue => e
      emsg = "failed to complete both password change and key rotation: #{e.message}"
      $stderr.puts("error: #{emsg}")
      puts unless $stdout.isatty
      exit(1)
    end

    # Print the successful password change message and new API key for the role
    puts
    puts(
      "Password changed and API key rotated for '#{args[:role_id]}'.\n\n" \
      "New API key: #{role.api_key}"
    )
  end

  # Set the new password
  def change_password_wrapper(role, password)
    begin
      Commands::Credentials::ChangePassword.new.call(
        role: role,
        password: password,
        client_ip: '127.0.0.1'
      )
    rescue => e
      raise("failed to change password: #{e.message}")
    end
  end

  # Reset the role's API key
  def rotate_key_wrapper(role)
    begin
      Commands::Credentials::RotateApiKey.new.call(
        role_to_rotate: role,
        authenticated_role: Struct.new(:id).new('local'),
        client_ip: '127.0.0.1'
      )
    rescue => e
      raise("failed to rotate API key: #{e.message}")
    end
  end
end
