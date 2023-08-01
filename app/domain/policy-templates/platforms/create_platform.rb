# frozen_string_literal: true
require_relative '../base_template'

module PolicyTemplates
  class CreatePlatform < PolicyTemplates::BaseTemplate
    def template
      <<~TEMPLATE
        - !policy
          id: <%= id %>
          body:
          - !permit
            role: !group delegation/secrets-creators
            privileges: [ use ]
            resource: !policy

          - !permit
            role: !group delegation/secrets-creators
            privileges: [ read, execute ]
            resource: !variable secrets/default

          - !permit
            role: !group delegation/secrets-creators
            privileges: [ update ]
            resource: !policy secrets

          - !permit
            role: !group delegation/consumers
            privileges: [ read, execute ]
            resource: !variable secrets/default
           
          - !policy
            id: delegation
            body:
            - !group secrets-creators
            - !group consumers

          - !policy
            id: secrets
            body:
            - !variable
              id: default
              annotations:
                platform/id: <%= id %>
                platform/method: <%= default_secret_method %>
      TEMPLATE
    end
  end
end