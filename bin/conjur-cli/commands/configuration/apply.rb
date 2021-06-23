# frozen_string_literal: true

require 'command_class'
require 'open3'

module Commands
  module Configuration
    Apply ||= CommandClass.new(
      dependencies: {
        command_runner: Open3,
        process_manager: Process,
        output_stream: $stdout
      },

      inputs: %i[
        test_mode
      ]
    ) do
      def call
        if @test_mode
          @output_stream.puts(
            "Configuration is valid. Server will not be restarted in test mode."
          )
          return
        end

        pid = server_pid

        if pid.zero?
          raise 'Conjur is not currently running, please start it with conjurctl server.'
        end

        # This will attempt to do a phased restart but will fall back to a
        # normal restart if phased is not available due to preloading.
        @process_manager.kill('USR1', pid)

        @output_stream.puts(
          "Conjur server reboot initiated. New configuration will be applied."
        )
      end

      private

      def server_pid
        # We use string concatenation here to allow for comments on each
        # part of the command.
        # rubocop:disable Style/StringConcatenation
        cmd = "ps -ef | " +
          # Filter to only puma processes
          "grep puma | " +
          # Filter to only puma process for the Conjur API Server. This tag
          # is defined in the `config/puma.rb`.
          "grep '\\[Conjur API Server\\]' | " +
          # Filter out the grep processes
          "grep --invert-match grep | " +
          # Filter out the cluster worker processes
          "grep --invert-match cluster | " +
          # Extract the process ID
          "awk '{print $2}' | tr --delete '\n'"
        # rubocop:enable Style/StringConcatenation

        stdout, = @command_runner.capture2(cmd)
        stdout.to_i
      end
    end
  end
end
