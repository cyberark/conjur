# frozen_string_literal: true

require_relative '../base_template'

module PolicyTemplates
  class CreateIssuer < PolicyTemplates::BaseTemplate
    def template
      <<~TEMPLATE
        - !policy
          id: "{{id}}"
          body:
          - !permit
            role: !group delegation/consumers
            privileges: [ read, use ]
            resource: !policy

          - !policy
            id: delegation
            body:
            - !group consumers
      TEMPLATE
    end
  end
end
