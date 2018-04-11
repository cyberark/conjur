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
  # The result of loading a policy. When a policy is loaded, two types of data
  # are always provided:
  #
  # * {#created_roles} the API keys of any new roles which were created
  # * {#version} the new version of the policy.
  class PolicyLoadResult
    def initialize data
      @data = data
    end
    
    # @api private
    def to_h
      @data
    end
    
    # @api private
    def to_json options = {}
      @data.to_json(options)
    end
    
    # @api private
    def to_s
      @data.to_s
    end

    # API keys for roles which were created when loading the policy.
    #
    # @return [Hash] Hash keys are the role ids, and hash values are the API keys.    
    def created_roles
      @data['created_roles']
    end
    
    # The new version of the policy. When a policy is updated, a new version is appended
    # to that policy. The YAML of previous versions of the policy can be obtained 
    # by fetching the policy resource using {API#resource}.
    def version
      @data['version']
    end
  end
end
