# frozen_string_literal: true

require 'command_class'
require 'conjur/conjur_config'
require 'json'

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
