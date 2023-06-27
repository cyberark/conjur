# frozen_string_literal: true


module Templates
  module TemplatesRenderer
    def call(template: BaseTemplate)
      ERB.new(template.template)
    end
  end
end