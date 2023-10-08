# frozen_string_literal: true

module Authentication
  module OptionalApiKey

    AUTHN_ANNOTATION = 'authn/api-key'

    def annotation_relevant?(annotation)
      annotation.name == AUTHN_ANNOTATION
    end

    def annotation_true?(annotation)
      annotation_relevant?(annotation) && annotation.value.downcase == 'true'
    end

    def update_role_credentials(role)
      credentials = Credentials[role_id: role.id]
      credentials.api_key = role.api_key
      credentials.save
      credentials.api_key
    end
  end
end
