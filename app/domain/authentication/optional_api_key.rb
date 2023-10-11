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

  end
end
