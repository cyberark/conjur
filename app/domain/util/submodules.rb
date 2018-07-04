# frozen_string_literal: true

module Util
  class Submodules
    def self.of(mod)
      mod.constants
        .map { |c| mod.const_get(c) }
        .select { |x| x.is_a?(Module) }
    end
  end
end
