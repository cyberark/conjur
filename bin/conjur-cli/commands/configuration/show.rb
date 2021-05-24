# frozen_string_literal: true

require 'command_class'
require 'conjur/conjur_config'
require 'json'

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
    Show ||= CommandClass.new(
      dependencies: {
        conjur_config: Conjur::ConjurConfig.new,
        output_stream: $stdout
      },

      inputs: %i[
        output_format
      ]
    ) do
      def call
        @output_stream.puts(
          formatted_config
        )
      end

      def formatted_config
        case @output_format
        when 'json'
          json_formatted_config
        when 'yaml', 'text'
          yaml_formatted_config
        else
          raise("Unknown configuration output format '#{@output_format}'")
        end
      end

      def json_formatted_config
        JSON.pretty_generate(display_configuration)
      end

      def yaml_formatted_config
        display_configuration.to_yaml
      end

      def display_configuration
        @conjur_config.to_source_trace.map do |key, value|
          [
            key.to_s,
            {
              'value' => value[:value],
              'source' => value.dig(:source, :type).to_s
            }
          ]
        end.to_h
      end
    end
  end
end
