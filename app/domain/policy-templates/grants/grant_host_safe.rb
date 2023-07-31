# frozen_string_literal: true
require_relative '../base_template'

module PolicyTemplates
  class GrantHostSafe < PolicyTemplates::BaseTemplate
    def template
      <<~TEMPLATE
        - !grant
          role: !group delegation/consumers
          member: !host <%= id %>
      TEMPLATE
    end
  end
end