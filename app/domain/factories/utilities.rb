# frozen_string_literal: true

module Factories
  # Provides utility methods for Factories
  class Utilities
    # Filter non-alpha-numeric, dash, forward slash, or underscore characters from values (to prevent injection attacks)
    def self.filter_input(str)
      regex = Regexp.new('[^0-9a-z,\-_\/]', Regexp::IGNORECASE)
      str.gsub(regex, '')
    end
  end
end
