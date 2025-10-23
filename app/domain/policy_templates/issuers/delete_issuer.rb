# frozen_string_literal: true

module PolicyTemplates
  module Issuers
    class DeleteIssuer < PolicyTemplates::BaseTemplate
      def template
        <<~TEMPLATE
          - !delete
            record: !group {{id}}/delegation/consumers

          - !delete
            record: !policy {{id}}/delegation

          - !delete
            record: !policy {{id}}
        TEMPLATE
      end
    end
  end
end
