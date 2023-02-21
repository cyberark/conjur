module Factory
  class RenderPolicy
    def initialize(render_engine: ERB)
      @render_engine = render_engine
    end

    def render(template:, variables:)
      @render_engine.new(template, nil, '-').result_with_hash(variables)
    end
  end
end
