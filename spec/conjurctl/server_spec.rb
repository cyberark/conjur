require 'spec_helper'
require 'open3'

describe "conjurctl server" do
  def delete_account(name)
    system("conjurctl account delete #{name}")
  end

  # Wait for conjur server to be up.
  # Exit if it takes longer than 60 seconds
  def wait_for_conjur
    system("conjurctl wait --retries 60")
  end

  context "start server" do
    after(:each) do
      delete_account("demo")
    end

    it "with password-from-stdin flag but no account flag" do
      _, stderr_str, = Open3.capture3(
        "conjurctl server --password-from-stdin"
      )
      expect(stderr_str).to include("account is required")
      expect(Slosilo["authn:demo"]).not_to be
      expect(Role["demo:user:admin"]).not_to be
    end

    it "with account flag" do
      with_background_process(
        'conjurctl server --account demo'
      ) do
        wait_for_conjur
        expect(Slosilo["authn:demo"]).to be
        expect(Role["demo:user:admin"]).to be
      end
    end

    it "with both account and password-from-stdin flags" do
      with_background_process("
        echo -n 'MySecretP,@SS1()!' |
        conjurctl server --account demo --password-from-stdin
        ") do
        wait_for_conjur
        expect(Slosilo["authn:demo"]).to be
        expect(Role["demo:user:admin"]).to be
      end
    end

    it "deletes an existing PID file on start up" do
      pid_file_path = File.join(conjur_server_dir, 'tmp/pids/server.pid')

      # Ensure the pid file exists before starting Conjur
      FileUtils.mkdir_p(File.dirname(pid_file_path))
      FileUtils.touch(pid_file_path)

      # Start Conjur and wait for it to finish its initialization
      output = with_background_process(
        'conjurctl server --account demo'
      ) do
        # Let Conjur finish starting to gather the standard
        # output and then exit it.
        wait_for_conjur
      end

      # Ensure that the Conjur output reports that the PID was removed
      expect(output).to include(
        "Removing existing PID file: #{pid_file_path}"
      )
    end

    it "doesn't attempt to delete a non-existent PID file" do
      pid_file_path = File.join(conjur_server_dir, 'tmp/pids/server.pid')

      # Ensure the pid file doesn't exist before starting Conjur
      File.delete(pid_file_path) if File.exist?(pid_file_path)

      # Start Conjur and wait for it to finish its initialization
      output = with_background_process(
        'conjurctl server --account demo'
      ) do
        # Let Conjur finish starting to gather the standard
        # output and then exit it.
        wait_for_conjur
      end

      # Ensure that the Conjur output doesn't report that the PID was removed
      expect(output).not_to include(
        "Removing existing PID file: #{pid_file_path}"
      )
    end

    it "deletes an existing PID file on start up" do
      pid_file_path = File.join(conjur_server_dir, 'tmp/pids/server.pid')

      # Ensure the pid file exists before starting Conjur
      FileUtils.mkdir_p(File.dirname(pid_file_path))
      FileUtils.touch(pid_file_path)

      # Start Conjur and wait for it to finish its initialization
      output = with_background_process(
        'conjurctl server --account demo'
      ) do
        wait_for_conjur
      end

      # Ensure that the Conjur output reports that the PID was removed
      expect(output).to include(
        "Removing existing PID file: #{pid_file_path}"
      )
    end

    it "doesn't attempt to delete a non-existent PID file" do
      pid_file_path = File.join(conjur_server_dir, 'tmp/pids/server.pid')

      # Ensure the pid file doesn't exist before starting Conjur
      File.delete(pid_file_path) if File.exist?(pid_file_path)

      # Start Conjur and wait for it to finish its initialization
      output = with_background_process(
        'conjurctl server --account demo'
      ) do
        wait_for_conjur
      end

      # Ensure that the Conjur output doesn't report that the PID was removed
      expect(output).not_to include(
        "Removing existing PID file: #{pid_file_path}"
      )
    end
  end
end
