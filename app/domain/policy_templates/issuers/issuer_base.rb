# frozen_string_literal: true

require_relative '../base_template'

module PolicyTemplates
  class IssuerBase < PolicyTemplates::BaseTemplate
    def template
      <<~TEMPLATE
        - !policy
          id: conjur/issuers
      TEMPLATE
    end
  end
end
