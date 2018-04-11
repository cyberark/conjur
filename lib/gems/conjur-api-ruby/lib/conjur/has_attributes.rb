#
# Copyright 2013-2017 Conjur Inc
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
  # Many Conjur assets have key-value attributes.  Although these should generally be accessed via
  # methods on specific asset classes (for example, {Conjur::Resource#owner}), the are available as
  # a `Hash` on all types supporting attributes.
  module HasAttributes
    class << self

      # @api private
      def annotation_value annotations, name
        (annotations.find{|a| a['name'] == name} || {})['value']
      end
    end

    def as_json options={}
      result = super(options)
      if @attributes
        result.merge!(@attributes.as_json(options))
      end
      result
    end
    
    def to_s
      to_json.to_s
    end

    # @api private
    # Set the attributes for this Resource.
    # @param [Hash] attributes new attributes for the object.
    # @return [Hash] the new attributes
    def attributes=(attributes); @attributes = attributes; end

    # Get the attributes for this asset. This is an immutable Hash, unless the attributes
    # are changed via policy update.
    #
    # @return [Hash] the asset's attributes.
    def attributes
      return @attributes if @attributes
      fetch
    end

    # Call a block that will perform actions that might change the asset's attributes.
    # No matter what happens in the block, this method ensures that the cached attributes
    # will be invalidated.
    #
    # @note this is mainly used internally, but included in the public api for completeness.
    #
    # @return [void]
    def invalidate(&block)
      yield
    ensure
      @attributes = nil
    end


    protected

    def annotation_value name
      HasAttributes.annotation_value attributes['annotations'], name
    end

    # @api private
    # Fetch the attributes, overwriting any current ones.
    def fetch
      @attributes ||= fetch_attributes
    end

    # @api private
    def fetch_attributes
      cache_key = Conjur.cache_key username, url_for(:resources_resource, credentials, id).url
      Conjur.cache.fetch_attributes cache_key do
        JSON.parse(url_for(:resources_resource, credentials, id).get.body)
      end
    end
  end
end