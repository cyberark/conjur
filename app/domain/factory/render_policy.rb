module Factory
  class RenderPolicy
    def initialize(render_engine: ERB)
      @render_engine = render_engine
    end

    def render(policy_template:, variables:)
      @render_engine.new(policy_template, nil, '-').result_with_hash(variables)
    end
  end
end
