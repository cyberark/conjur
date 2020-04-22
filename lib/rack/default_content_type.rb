# frozen_string_literal: true

require 'forwardable'

module Rack

  # DefaultContentType is a Rack middleware that supports
  # providing a default Content-Type header for requests
  # to specific paths that do not include a Content-Type
  # header in the request.
  #
  # Default content types are configured by adding entries
  # to the Rack::DefaultContentType.default_content_types
  # class member hash.
  #
  # Each hash key must be a regular expression to test
  # request paths for a match. The hash value is the content
  # type string to add to the request.
  #
  class DefaultContentType

    # A Hash-like whose keys are Regex objects. It looks up values by matching
    # keys given to its #[] method against those regexes, and returning the
    # value of the first match.
    class RegexHash
      extend Forwardable

      # Note: this will work with a Hash or keyword args
      def initialize(**kwargs)
        @vals_by_regex = kwargs
      end

      def [](key)
        matching_re = @vals_by_regex.each_key.find { |re, _| re =~ key }
        @vals_by_regex[matching_re] # Note: returns nil if no match
      end

      def_delegators :@vals_by_regex, :[]=
    end

    def self.content_type_by_path
      @content_type_by_path ||= RegexHash.new
    end

    def initialize(app)
      @app = app
    end

    # :reek:DuplicateMethodCall
    def call(env)
      # If a content type is already present on the request, we
      # don't need to do anything
      if content_type_missing?(env) && default_content_type(env)
        env['CONTENT_TYPE'] = default_content_type(env)
        Rack::Request.new(env).body.rewind
      end

      @app.call(env)
    end

    # :reek:UtilityFunction
    # :reek:NilCheck
    def content_type_missing?(env)
      env['CONTENT_TYPE']&.empty?
    end

    # :reek:UtilityFunction
    def default_content_type(env)
      Rack::DefaultContentType.content_type_by_path[env['PATH_INFO']]
    end
  end
end
