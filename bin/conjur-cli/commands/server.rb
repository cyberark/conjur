# frozen_string_literal: true

require 'command_class'

# Required to use $CHILD_STATUS
require 'English'

require_relative 'db/migrate'

module Commands
  Server ||= CommandClass.new(
    dependencies: {
      migrate_database: DB::Migrate.new
    },

    inputs: %i[
      account
      password_from_stdin
      file_name
      bind_address
      port
    ]
  ) do
    def call
      # Ensure the database is available
      # and the schema is up-to-date
      @migrate_database.call(
        preview: false
      )

      # Create and bootstrap the initial
      # Conjur account and policy
      create_account
      load_bootstrap_policy

      # Remove a stale puma PID file, if it exists
      cleanup_pidfile

      # Start the Conjur API and service
      # processes
      fork_server_process
      fork_authn_local_process
      fork_rotation_process

      # Block until all child processes end
      wait_for_child_processes
    end

    private

    def migrate_database
      system("rake db:migrate") || exit(($CHILD_STATUS.exitstatus))
    end

    def create_account
      if @password_from_stdin && !@account
        raise "account is required with password-from-stdin flag"
      end

      return unless @account

      if @password_from_stdin
        # Rake is interpreting raw commas in the password as
        # delimiting addtional arguments to rake itself.
        # Reference: https://github.com/ruby/rake/blob/a842fb2c30cc3ca80803fba903006b1324a62e9a/lib/rake/application.rb#L163
        password = stdin_input.gsub(',', '\,')
        system(
          "rake 'account:create_with_password[#{@account},#{password}]'"
        ) || exit(($CHILD_STATUS.exitstatus))
      else
        system(
          "rake 'account:create[#{@account}]'"
        ) || exit(($CHILD_STATUS.exitstatus))
      end
    end

    def stdin_input
      raise "Please provide an input via STDIN" if $stdin.tty?

      $stdin.read.force_encoding('ASCII-8BIT')
    end

    def load_bootstrap_policy
      return unless @file_name

      raise "account option is required with file option" unless @account

      system(
        "rake 'policy:load[#{@account},#{@file_name}]'"
      ) || exit(($CHILD_STATUS.exitstatus))
    end

    # This method is needed because in some versions of conjur server it has been observed that
    # docker restart of the conjur server results in an error stating that the puma PID file is still present.
    # Hence we check to see if this stale PID File exists and delete it, which ensures a smooth restart.
    # This issue is described in detail in Issue 2381.

    def cleanup_pidfile
      # Get the path to conjurctl
      conjurctl_path = `readlink -f $(which conjurctl)`
    
      # Navigate from its directory (/bin) to the root Conjur server directory
      conjur_server_dir = Pathname.new(File.join(File.dirname(conjurctl_path), '..')).cleanpath
      pid_file_path = File.join(conjur_server_dir, 'tmp/pids/server.pid')
      return unless File.exist?(pid_file_path)
      
      puts("Removing existing PID file: #{pid_file_path}")
      File.delete(pid_file_path)
    end

    def fork_server_process
      Process.fork do
        puts("Conjur v#{conjur_version} starting up...")

        exec("
          rails server -p '#{@port}' -b '#{@bind_address}'
        ")
      end
    end

    def conjur_version
      File.read(
        File.expand_path(
          "../../../VERSION",
          File.dirname(__FILE__)
        )
      ).strip
    end

    def fork_authn_local_process
      Process.fork do
        exec("rake authn_local:run")
      end
    end

    def fork_rotation_process
      # Only start the rotation watcher on leader, not on replicas
      #
      is_leader = !Sequel::Model.db['SELECT pg_is_in_recovery()'].first.values[0]
      return unless is_leader

      Process.fork do
        exec("rake expiration:watch")
      end

      # # Start the rotation "watcher" in a separate thread
      # rotations_thread = Thread.new do
      #   # exec "rake expiration:watch[#{account}]"
      #   # exec "rake expiration:watch"
      #   Rotation::MasterRotator.new(
      #     avail_rotators: Rotation::InstalledRotators.new
      #   ).rotate_every(1)
      #   end
      # # Kill all of Conjur if rotations stop working
      # rotations_thread.abort_on_exception = true
      # rotations_thread.join
    end

    def wait_for_child_processes
      Process.waitall
    end
  end
end
