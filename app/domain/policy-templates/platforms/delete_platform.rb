# frozen_string_literal: true
require_relative '../base_template'

module PolicyTemplates
  class DeletePlatform < PolicyTemplates::BaseTemplate
    def template
      <<~TEMPLATE
        - !delete
          record: !variable <%= id %>/secrets/default       
 
        - !delete
          record: !policy <%= id %>/secrets
       
        - !delete
          record: !group <%= id %>/delegation/consumers

        - !delete
          record: !group <%= id %>/delegation/secrets-creators

        - !delete
          record: !policy <%= id %>/delegation
        
        - !delete
          record: !policy <%= id %>
      TEMPLATE
    end
  end
end