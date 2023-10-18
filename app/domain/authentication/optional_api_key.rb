# frozen_string_literal: true

module Authentication
  module OptionalApiKey

    AUTHN_ANNOTATION = 'authn/api-key'

    def api_key_annotation_relevant?(annotation)
      annotation.name == AUTHN_ANNOTATION
    end

    def api_key_annotation_true?(annotation)
      api_key_annotation_relevant?(annotation) && annotation.value.downcase == 'true'
    end

  end
end
