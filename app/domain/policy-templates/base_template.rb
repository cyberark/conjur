# frozen_string_literal: true

module Templates
  class BaseTemplate
    def template
      throw NotImplementedError
    end
  end
end
