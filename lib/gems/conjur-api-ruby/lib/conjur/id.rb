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
  # Encapsulates a Conjur id, which consists of account, kind, and identifier.
  class Id
    attr_reader :id
    
    def initialize id
      @id = id
    end
    
    # The organization account, obtained from the first component of the id.
    def account; id.split(':', 3)[0]; end
    # The object kind, obtained from the second component of the id.
    def kind; id.split(':', 3)[1]; end
    # The object identifier, obtained from the third component of the id. The
    # identifier must be unique within the `account` and `kind`.
    def identifier; id.split(':', 3)[2]; end
    
    # Defines id equivalence using the string representation.
    def == other
      if other.is_a?(String)
        to_s == other
      else
        super
      end
    end

    # @return [String] the id string.
    def as_json options={}
      @id
    end

    # Splits the id into 3 components, and then joins them with a forward-slash `/`.
    def to_url_path
      id.split(':', 3).join('/')
    end
    
    # @return [String] the id string
    def to_s
      id
    end
  end
end
