# frozen_string_literal: true

# NOTE: These two lines are important for security.
#
# They prevent Rack from interpreting request bodies as form parameters
# and stuffing them in the params hash, which ends up in logs.
# It's better to explicitly parse form data where required.

Rack::Request::FORM_DATA_MEDIA_TYPES.clear
Rack::Request::PARSEABLE_DATA_MEDIA_TYPES.clear
