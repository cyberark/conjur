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
require 'conjur/resource'

module Conjur
  class API
    include QueryString
    include BuildObject
    
    #@!group Resources

    # Find a resource by it's id.  The id given to this method must be qualified by a kind, but the account is
    # optional.
    #
    # ### Permissions
    #
    # The resource **must** be visible to the current role.  This is the case if the current role is the owner of
    # the resource, or has any privilege on it.
    #
    # @param id [String] a fully qualified resource identifier
    # @return [Conjur::Resource] the resource, which may or may not exist
    def resource id
      build_object id
    end

    # Find all resources visible to the current role that match the given search criteria.
    #
    # ## Full Text Search
    # Conjur supports full text search over the identifiers and annotation *values*
    # of resources.  For example, if `opts[:search]` is `"pubkeys"`, any resource with
    # an id containing `"pubkeys"` or an annotation whose value contains `"pubkeys"` will match.
    #
    # **Notes**
    #   * Annotation *keys* are *not* indexed for full text search.
    #   * Conjur indexes the content of ids and annotation values by word.
    #   * Only resources visible to the current role (either owned by that role or
    #       having a privilege on it) are returned.
    #   * If you do not provide `:offset` or `:limit`, all records will be returned. For systems
    #       with a huge number of resources, you may want to paginate as shown in the example below.
    #   * If `:offset` is provided and `:limit` is not, 10 records starting at `:offset` will be
    #       returned.  You may choose an arbitrarily large number for `:limit`, but the same performance
    #       considerations apply as when omitting `:offset` and `:limit`.
    #
    # @example Search for resources annotated with the text "WebService Route"
    #    webservice_routes = api.resources search: "WebService Route"
    #
    # @example Restrict the search to 'group' resources
    #   groups = api.resources kind: 'group'
    #
    #   # Correct behavior:
    #   expect(groups.all?{|g| g.kind == 'group'}).to be_true
    #
    # @example Get every single resource in a performant way
    #   resources = []
    #   limit = 25
    #   offset = 0
    #   until (batch = api.resources limit: limit, offset: offset).empty?
    #     offset += batch.length
    #     resources.concat results
    #   end
    #   # do something with your resources
    #
    # @param options [Hash] search criteria
    # @option options [String]   :search find resources whose ids or annotations contain this string
    # @option options [String]   :kind find resources whose `kind` matches this string
    # @option options [Integer]  :limit the maximum number of records to return (Conjur may return fewer)
    # @option options [Integer]  :offset offset of the first record to return
    # @option options [Boolean]  :count return a count of records instead of the records themselves when set to true
    # @return [Array<Conjur::Resource>] the resources matching the criteria given
    def resources options = {}
      options = { host: Conjur.configuration.core_url, credentials: credentials }.merge options
      options[:account] ||= Conjur.configuration.account
      
      host, credentials, account, kind = options.values_at(*[:host, :credentials, :account, :kind])
      fail ArgumentError, "host and account are required" unless [host, account].all?
      %w(host credentials account kind).each do |name|
        options.delete(name.to_sym)
      end

      result = JSON.parse(url_for(:resources, credentials, account, kind, options).get)

      result = result['count'] if result.is_a?(Hash)

      if result.is_a?(Numeric)
        result
      else
        result.map do |result|
          resource(result['id']).tap do |r|
            r.attributes = result
          end
        end
      end
    end
  end
end
