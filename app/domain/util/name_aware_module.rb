# frozen_string_literal: true

module Util
  class NameAwareModule < SimpleDelegator

    def own_name
      name_parts.last
    end

    def parent_name
      name_parts[-2]
    end

    private

    def name_parts
      name.split('::')
    end
  end
end
