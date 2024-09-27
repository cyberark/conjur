require 'responses'

module Factories
  class Renderer
    def initialize(render_engine: Mustache.new)
      @render_engine = render_engine

      @success = ::SuccessResponse
      @failure = ::FailureResponse
    end

    def transform_variables(variables)
      {}.tap do |new_variables|
        variables.each do |key, value|
          new_variables[key.to_s] = if variables[key].is_a?(Hash)
            convert_to_mustache_hash(variables[key])
          elsif variables[key].is_a?(String) && variables[key].empty?
            nil
          elsif variables[key].nil?
            nil
          else
            value.to_s
          end
        end
      end
    end

    def render(template:, variables:)
      response = @render_engine.render(template, transform_variables(variables))

      # Return unless the template is missing an opening tag
      return @success.new(response) unless response.match(/\}\}/)

      @failure.new('Template includes invalid syntax')
    rescue Mustache::Parser::SyntaxError
      # There is an issue with the SyntaxError class in the Mustache gem, which
      # causes an error when attempting to render the error message in the
      # context of a parse error. For this reason, we're just returning a
      # generic error message.
      @failure.new('Template includes invalid syntax')
    rescue => e
      # Need to add tests to understand what exceptions are thrown when
      # variables are missing. This may not be enough.
      @failure.new(
        "An error occurred while rendering the template: #{e.message}"
      )
    end

    private

    # Mustache does not like processing hashes into key/value pairs. This
    # is a workaround to convert a hash into a format that Mustache can
    # better understand.
    def convert_to_mustache_hash(hsh)
      [].tap do |rtn_array|
        hsh.each do |key, value|
          rtn_array.push(
            {
              'key' => key.to_s,
              'value' => value.to_s
            }
          )
        end
      end
    end
  end
end
