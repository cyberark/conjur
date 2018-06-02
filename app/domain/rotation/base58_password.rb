require 'base58'

module Rotation

  # Include this class to get a #generate_password class and instance method.
  module PasswordGeneration

    # Use the first char of Base58::ALPHABET to pad zeros
    ZERO_PAD_CHAR = Base58::ALPHABET[0]

    def self.included base
      base.send :extend, self
    end

    # Generates a password with length of +length+ characters.  The characters
    # are selected from the Base58 alphabet (see https://en.wikipedia.org/wiki/Base58)
    #
    # This means that your password will have a space of 58 ^ length.  Passwords
    # are generated using the ruby `SecureRandom` library.
      def generate_password length

        # SecureRandom.random_number decides what kind of number to generate
        # based on whether its argument is positive and a Fixnum.
        raise ArgumentError, "length must be greater than 0" if length <= 0
        raise ArgumentError, "length must be an integer" unless length.kind_of?(Integer)

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
        Base58.int_to_base58(SecureRandom.random_number(58 ** length)).rjust(length, ZERO_PAD_CHAR)
      end
  end
end
