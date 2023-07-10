module Utilities
  class ScenarioContext
    def initialize
      @context = {}
    end

    def set(key, value)
      @context[key] = value
    end

    alias add set

    def key?(key)
      @context.key?(key)
    end

    def get(key)
      raise "Scenario Context: '#{key}' has not been defined" unless key?(key)

      @context[key]
    end

    def reset!
      @context = {}
    end
  end
end
