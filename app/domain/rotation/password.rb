# frozen_string_literal: true

require 'base58'
require 'securerandom'

module Rotation

  # Generates a password with length of +length+ characters.  The characters
  # are selected from the Base58 alphabet (see https://en.wikipedia.org/wiki/Base58)
  #
  # This means that your password will have a space of 58 ^ length.  Passwords
  # are generated using the ruby `SecureRandom` library.
  class Password

    # Use the first char of the default alphabet to pad zeros
    #
    ZERO_PAD_CHAR = Base58::ALPHABETS[:flickr][0]

    def self.base58(length:)

      valid = length.is_a?(Integer) && length > 0
      raise ArgumentError, "length must be a positive integer" unless valid

      # Here's what we're doing:
      # Generate a random bigint between 0 and (58 ^ length).  This is guaranteed to
      # have length in base58 of at most length.
      #
      # We handle shorter strings (numbers less than 58^(length - 1)) by
      # filling in leading 0s.  Note that this does not affect the randomness
      # of the generated passwords as generating each character individually
      # would produce sequences of K leading ones at exactly the same rate
      # that generating random numbers generates numbers less than 58^(length
      # - K)

      rand_int = SecureRandom.random_number(58 ** length)
      Base58.int_to_base58(rand_int, :flickr).rjust(length, ZERO_PAD_CHAR)
    end
  end
end
