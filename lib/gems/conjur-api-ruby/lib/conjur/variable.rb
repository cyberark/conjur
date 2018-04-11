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

  # Protected (secret) data stored in Conjur.
  # 
  # The code responsible for the actual encryption of variables is open source as part of the
  # {https://github.com/conjurinc/slosilo Slosilo} library.
  #
  # Each variables has some standard metadata (`mime-type` and secret `kind`).
  #
  # Variables are *versioned*.  Storing secrets in multiple places is a bad security practice, but
  # overwriting a secret accidentally can create a major problem for development and ops teams.  Conjur
  # discourages bad security practices while avoiding ops disasters by storing previous versions of
  # a secret (up to a fixed limit, to avoid unbounded database growth).
  #
  # ### Important
  # A common pitfall when trying to access older versions of a variable is to assume that `0` is the oldest
  # version.  Variable versions are `1`-based, with `1` being the oldest.
  #
  # ### Permissions
  #
  # * To *fetch* the value of a `variable`, you must have permission to `'execute'` the variable.
  # * To *add* a value to a `variable`, you must have permission to `'update'` the variable.
  # * To *show* metadata associated with a variable, but *not* the value of the secret, you must have `'read'`
  #     permission on the variable.
  #
  # @example Get a variable and access its metadata and the latest value
  #   variable = api.resource 'myorg:variable:example'
  #   puts variable.kind      # "example-secret"
  #   puts variable.mime_type # "text/plain"
  #   puts variable.value     # "supahsecret"

  # @example Variables are versioned
  #   variable = api.resource 'myorg:variable:example'
  #   # Unless you set a variables value when you create it, the variable starts out without a value and version_count
  #   # is 0.
  #   var.version_count # => 0
  #   var.value # raises RestClient::ResourceNotFound (404)
  #
  #   # Add a value
  #   var.add_value 'value 1'
  #   var.version_count # => 1
  #   var.value # => 'value 1'
  #
  #   # Add another value
  #   var.add_value 'value 2'
  #   var.version_count # => 2
  #
  #   # 'value' with no argument returns the most recent value
  #   var.value # => 'value 2'
  #
  #   # We can access older versions by their 1 based index:
  #   var.value 1 # => 'value 1'
  #   var.value 2 # => 'value 2'
  #   # Notice that version 0 of a variable is always the most recent:
  #   var.value 0 # => 'value 2'
  #
  class Variable < BaseObject
    include ActsAsResource

    def as_json options={}
      result = super(options)
      result["mime_type"] = mime_type
      result["kind"] = kind
      result
    end
    
    # The kind of secret represented by this variable,  for example, `'postgres-url'` or
    # `'aws-secret-access-key'`.
    #
    # You must have the **`'read'`** permission on a variable to call this method.
    #
    # This attribute is only for human consumption, and does not take part in the Conjur permissions
    # model.
    #
    # @note this is **not** the same as the `kind` part of a qualified Conjur id.
    # @return [String] a string representing the kind of secret.
    def kind
      parser_for(:variable_kind, variable_attributes) || "secret"
    end

    # The MIME Type of the variable's value.
    #
    # You must have the **`'read'`** permission on a variable to call this method.
    #
    # This attribute is used by the Conjur services to set a response `Content-Type` header when
    # returning the value of a variable.  Conjur applies the same MIME Type to all versions of a variable,
    # so if you plan on accessing the variable in a way that depends on a correct `Content-Type` header
    # you should make sure to store appropriate data for the mime type in all versions.
    #
    # @return [String] a MIME type, such as `'text/plain'` or `'application/octet-stream'`.
    def mime_type
      parser_for(:variable_mime_type, variable_attributes) || "text/plain"
    end

    # Add a new value to the variable.
    #
    # You must have the **`'update'`** permission on a variable to call this method.
    #
    # @example Add a value to a variable
    #   var = api.variable 'my-secret'
    #   puts var.version_count     #  1
    #   puts var.value             #  'supersecret'
    #   var.add_value "new_secret"
    #   puts var.version_count     # 2
    #   puts var.value             # 'new_secret'
    # @param [String] value the new value to add
    # @return [void]
    def add_value value
      log do |logger|
        logger << "Adding a value to variable #{id}"
      end
      invalidate do
        route = url_for(:secrets_add, credentials, id)
        Conjur.configuration.version_logic lambda {
            route.post value: value
          }, lambda {
            route.post value
          }
      end
    end

    # Return the number of versions of the variable.
    #
    # You must have the **`'read'`** permission on a variable to call this method.
    #
    # @example
    #   var.version_count # => 4
    #   var.add_value "something new"
    #   var.version_count # => 5
    #
    # @return [Integer] the number of versions
    def version_count
      Conjur.configuration.version_logic lambda {
          JSON.parse(url_for(:variable, credentials, id).get)['version_count']
        }, lambda {
          secrets = attributes['secrets']
          if secrets.empty?
            0
          else
            secrets.last['version']
          end
        }
    end

    # Return the version of a variable.
    #
    # You must have the **`'execute'`** permission on a variable to call this method.
    #
    # When no argument is given, the most recent version is returned.
    #
    # When a `version` argument is given, the method returns a version according to the following rules:
    #  * If `version` is 0, the *most recent* version is returned.
    #  * If `version` is less than 0 or greater than {#version_count}, a `RestClient::ResourceNotFound` exception
    #   will be raised.
    #  * If {#version_count} is 0, a `RestClient::ResourceNotFound` exception will be raised.
    #  * If `version` is >= 1 and `version` <= {#version_count}, the version at the **1 based** index given by `version`
    #    will be returned.
    #
    # @example Fetch all versions of a variable
    #   versions = (1..var.version_count).map do |version|
    #     var.value version
    #   end
    #
    # @example Get the current version of a variable
    #   # All of these return the same thing:
    #   var.value
    #   var.value 0
    #   var.value var.version_count
    #
    # @example Get the value of an expired variable
    #   var.value nil, show_expired: true
    #
    # @param [Integer] version the **1 based** version.
    # @param options [Hash]
    # @option options [Boolean, false] :show_expired show value even if variable has expired
    # @return [String] the value of the variable
    def value version = nil, options = {}
      options['version'] = version if version
      url_for(:secrets_value, credentials, id, options).get.body
    end

    private

    def variable_attributes
      @variable_attributes ||= url_for(:variable_attributes, credentials, self, id)
    end
  end  
end
