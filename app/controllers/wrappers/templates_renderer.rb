# frozen_string_literal: true

require 'mustache'

module PolicyTemplates
  module TemplatesRenderer
    def renderer(template, hash_input = {})
      Mustache.render(template.template, hash_input)
    end
  end
end
