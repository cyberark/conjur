# frozen_string_literal: true

# module Domain
module Validation
  NAME_LENGTH_MIN = 1
  NAME_LENGTH_MAX = 60
  NAME_PATTERN = /\A[A-Za-z0-9\-_]+\Z/.freeze
  NAME_PATTERN_MSG = "Wrong name '%{value}'"

  PATH_LENGTH_MIN = 1
  PATH_LENGTH_MAX = 500
  PATH_PATTERN = %r{\A[A-Za-z0-9\-_/]+\Z}.freeze
  PATH_PATTERN_MSG = "Wrong path '%{value}'"
  USER_PATH_PATTERN = %r{\A[A-Za-z0-9@\-_/]+\Z}.freeze
  USER_PATH_PATTERN_MSG = "Wrong path '%{value}'"

  IDENTIFIER_MAX_DEPTH = 15
  IDENTIFIER_MAX_DEPTH_MSG = "The number of identifier nesting exceeds maximum depth of #{IDENTIFIER_MAX_DEPTH}"
  IDENTIFIER_MAX_LENGTH = 950
  IDENTIFIER_MAX_LENGTH_MSG = "Identifier exceeds maximum length of #{IDENTIFIER_MAX_LENGTH} characters"

  def validate_identifier(identifier)
    depth = identifier.delete_prefix('/').delete_suffix('/').count('/') + 1
    raise DomainValidationError, IDENTIFIER_MAX_DEPTH_MSG if depth > IDENTIFIER_MAX_DEPTH
    raise DomainValidationError, IDENTIFIER_MAX_LENGTH_MSG if identifier.length > IDENTIFIER_MAX_LENGTH
  end

  class DomainValidationError < RuntimeError
  end
end
# end
