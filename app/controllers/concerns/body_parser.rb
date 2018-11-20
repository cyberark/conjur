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

  def decode_form_body
    Rack::Utils.parse_nested_query(request.body.read)
  end
end
