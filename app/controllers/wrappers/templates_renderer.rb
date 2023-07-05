# frozen_string_literal: true

module PolicyTemplates
  module TemplatesRenderer
    def renderer(template, hash_input)
      ERB.new(template.template, trim_mode: '-').result_with_hash(hash_input)
    end
  end
end