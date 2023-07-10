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

      # NOTE: this will work with a Hash or keyword args
      def initialize(**kwargs)
        @vals_by_regex = kwargs
      end

      def [](key)
        matching_re = @vals_by_regex.each_key.find { |re, _| re =~ key }
        @vals_by_regex[matching_re] # NOTE: returns nil if no match
      end

      def_delegators :@vals_by_regex, :[]=
    end

    def self.content_type_by_path
      @content_type_by_path ||= RegexHash.new
    end

    def initialize(app)
      @app = app
    end

    # This exhibits :reek:FeatureEnvy because it implements the default
    # content type behavior on `env` (an argument), rather than on internal state.
    #
    # It also has :reek:TooManyStatements, but to factor these out would make
    # the code less readable.
    def call(env)
      # added because our .NET SDK sends an invalid content type, but we
      # can't fix it now - need to remove later: ONYX-17641
      begin
        ::Mime::Type.lookup(env['CONTENT_TYPE']) if env['CONTENT_TYPE']
      rescue ::Mime::Type::InvalidMimeType
        ::Rails.logger.warn("Invalid content type passed in - #{env['CONTENT_TYPE']}")
        env.delete('CONTENT_TYPE')
        Rack::Request.new(env).body.rewind
      end

      content_type = env['CONTENT_TYPE']

      # Content type is missing if the header is absent or is empty
      content_type_present = content_type && !content_type.empty?
      default_content_type = Rack::DefaultContentType.content_type_by_path[env['PATH_INFO']]

      # If a content type is already present on the request, we
      # don't need to do anything
      if !content_type_present && default_content_type
        env['CONTENT_TYPE'] = default_content_type
        Rack::Request.new(env).body.rewind
      end

      @app.call(env)
    end
  end
end
