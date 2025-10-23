# frozen_string_literal: true

module PolicyTemplates
  module Issuers
    class IssuerBase < PolicyTemplates::BaseTemplate
      def template
        <<~TEMPLATE
          - !policy
            id: conjur/issuers
        TEMPLATE
      end
    end
  end
end
