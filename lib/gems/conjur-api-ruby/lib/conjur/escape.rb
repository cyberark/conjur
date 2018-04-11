#
# Copyright (C) 2013-2017 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
module Conjur

  # Provides helpers for escaping url components.
  #
  # The helpers are added as both class and isntance methods.
  module Escape
    module ClassMethods
      # URL escape the entire string.  This is essentially the same as calling `CGI.escape str`,
      # and then substituting `%20` for `+`.
      #
      # @example
      #   fully_escape 'foo/bar@baz'
      #   # => "foo%2Fbar%40baz"
      #
      # @example
      #   fully_escape 'test/Domain Controllers'
      #   # => "test%2FDomain%20Controllers"
      #
      # @param [String] str the string to escape
      # @return [String] the escaped string
      def fully_escape(str)
        # CGI escape uses + for spaces, which our services don't support :-(
        # We just gsub it.
        CGI.escape(str.to_s).gsub('+', '%20')
      end


      # Escape a URI path component.
      #
      # This method simply calls {Conjur::Escape::ClassMethods#path_or_query_escape}.
      #
      # @param [String] str the string to escape
      # @return [String] the escaped string
      # @see Conjur::Escape::ClassMethods#path_or_query_escape
      def path_escape(str)
        path_or_query_escape str
      end

      # Escape a URI query value.
      #
      # This method simply calls {Conjur::Escape::ClassMethods#path_or_query_escape}.
      #
      # @param [String] str the string to escape
      # @return [String] the escaped string
      # @see Conjur::Escape::ClassMethods#path_or_query_escape
      def query_escape(str)
        path_or_query_escape str
      end

      # Escape a path or query value.
      #
      # This method is *similar* to `URI.escape`, but it has several important differences:
      #   * If a falsey value is given, the string `"false"` is returned.
      #   * If the value given responds to `#id`, the value returned by `str.id` is escaped instead.
      #   * The value is escaped without modifying `':'` or `'/'`.
      #
      # @param [String, FalseClass, NilClass, #id] str the value to escape
      # @return [String] the value escaped as described
      def path_or_query_escape(str)
        return "false" unless str
        str = str.id if str.respond_to?(:id)
        # Leave colons and forward slashes alone
        require 'uri'
        pattern = URI::PATTERN::UNRESERVED + ":\\/@"
        URI.escape(str.to_s, Regexp.new("[^#{pattern}]"))
      end
    end

    # @api private
    def self.included(base)
      base.extend ClassMethods
    end

    # URL escape the entire string.  This is essentially the same as calling `CGI.escape str`.
    #
    # @example
    #   fully_escape 'foo/bar@baz'
    #   # => "foo%2Fbar%40baz"
    #
    # @param [String] str the string to escape
    # @return [String] the escaped string
    # @see Conjur::Escape::ClassMethods#fully_escape
    def fully_escape(str)
      self.class.fully_escape str
    end

    # Escape a URI path component.
    #
    # This method simply calls {Conjur::Escape::ClassMethods#path_or_query_escape}.
    #
    # @param [String] str the string to escape
    # @return [String] the escaped string
    # @see Conjur::Escape::ClassMethods#path_or_query_escape
    def path_escape(str)
      self.class.path_escape str
    end


    # Escape a URI query value.
    #
    # This method simply calls {Conjur::Escape::ClassMethods#path_or_query_escape}.
    #
    # @param [String] str the string to escape
    # @return [String] the escaped string
    # @see Conjur::Escape::ClassMethods#path_or_query_escape
    def query_escape(str)
      self.class.query_escape str
    end
  end
end
