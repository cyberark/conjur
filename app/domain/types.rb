# frozen_string_literal: true

require 'dry-types'
require 'dry-struct'

module Types
  include Dry::Types.module

  NonEmptyString ||= Types::Strict::String.constrained(format: /\S+/)
end
