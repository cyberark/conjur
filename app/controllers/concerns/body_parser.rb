# frozen_string_literal: true

# Mixin for controllers to parse body parameters.
#
# We disable parsing body parameters globally due to security concerns.
# Use this mixin instead if a controller specifically needs it.
module BodyParser
  # TODO: We are mass permitting all body params here.  This gives us
  #       feature parity with Rails 4 and simplifies the upgrade to 5,
  #       but a more Rails-5-in-spirit thing to do is upgrade all the
  #       call sites to permit only the expected params.
  #
  #       See: https://github.com/cyberark/conjur/issues/1467
  #
  # :reek:NilCheck should be acceptable here
  def body_params
    @body_params ||= ActionController::Parameters.new(
      case request.media_type
      when nil, 'application/x-www-form-urlencoded'
        decode_form_body
      when 'application/json'
        JSON.parse request.body.read
      else
        {}
      end
    ).permit!
  end

  def params
    super.merge body_params
  end

  private

  def decode_form_body
    Rack::Utils.parse_nested_query(request.body.read)
  end
end
