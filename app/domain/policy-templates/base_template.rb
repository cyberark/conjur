# frozen_string_literal: true

module PolicyTemplates
  class BaseTemplate
    def template
      raise NotImplementedError, "This method is not implemented because it's a base class"
    end
  end
end