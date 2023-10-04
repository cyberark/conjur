require 'responses'

module Factories
  class Renderer
    def initialize(render_engine: ERB)
      @render_engine = render_engine
      @success = ::SuccessResponse
      @failure = ::FailureResponse
    end

    def render(template:, variables:)
      @success.new(@render_engine.new(template, trim_mode: '-').result_with_hash(variables))

    # If variable in template is missing from variable list
    rescue NameError => e
      @failure.new("Required template variable '#{e.name}' is missing")
    rescue => e
      # Need to add tests to understand what exceptions are thrown when
      # variables are missing. This may not be enough.
      @failure.new(e)
    end
  end
end
