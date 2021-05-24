# frozen_string_literal: true

require 'command_class'
require 'conjur/conjur_config'
require 'open3'

# These are required to pull in the error class used in Conjur::ConjurConfig
# because the error class is not auto-loaded when running conjurctl commands
# since it's run outside of a full Rails environment. The fact that we have to
# do this indicates a scoping problem.
require 'domain/util/log_message_class'
require 'domain/util/trackable_log_message_class'
require 'domain/util/error_class'
require 'domain/util/trackable_error_class'
require 'domain/errors'

module Commands
  module Configuration
    Apply ||= CommandClass.new(
      dependencies: {
        conjur_config: Conjur::ConjurConfig.new,
        command_runner: Open3,
        process_manager: Process,
        output_stream: $stdout
      },

      inputs: %i[]
    ) do
      def call
        pid = server_pid

        if pid.zero?
          raise 'Conjur is not currently running, please start it with conjurctl server.'
        end

        @process_manager.kill('USR1', pid)

        @output_stream.puts(
          "Conjur server reboot initiated. New configuration will be applied."
        )
      end

      private

      def server_pid
        cmd = "ps -ef | grep puma | grep -v grep | grep -v cluster | " \
              "awk '{print $2}' | tr -d '\n'"
        stdout, _ = @command_runner.capture2(cmd)
        stdout.to_i
      end
    end
  end
end
