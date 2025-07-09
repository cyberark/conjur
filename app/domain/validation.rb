# frozen_string_literal: true

module Domain
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

    OWNER_KINDS = %w[host user group policy].freeze
    OWNER_KINDS_MSG = "'%{value}' is not a valid owner kind"

    class DomainValidationError < RuntimeError
    end
  end
end
