require 'responses'

module Factories
  class Renderer
    def initialize(render_engine: ERB)
      @render_engine = render_engine
      @success = ::SuccessResponse
      @failure = ::FailureResponse
    end

    def render(template:, variables:)
      binding.pry
      @success.new(@render_engine.new(template, nil, '-').result_with_hash(variables))
    rescue StandardError => e
      # Need to add tests to understand what exceptions are thrown when
      # variables are missing. This may not be enough.
      @failure.new(e)
    end
  end
end
