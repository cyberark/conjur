# frozen_string_literal: true

# Mixin for controllers to parse body parameters.
#
# We disable parsing body parameters globally due to security concerns.
# Use this mixin instead if a controller specifically needs it.
module BodyParser
  # :reek:NilCheck should be acceptable here
  def body_params
    @body_params ||= ActionController::Parameters.new \
      case request.media_type
      when nil, 'application/x-www-form-urlencoded'
        decode_form_body
      when 'application/json'
        JSON.parse request.body.read
      else
        {}
      end
  end

  def params
    super.merge body_params
  end

  private

  # note it does not parse rails magic [] params syntax, but we don't need it
  def decode_form_body
    Hash[*URI.decode_www_form(request.body.read).flatten(1)]
  end
end
