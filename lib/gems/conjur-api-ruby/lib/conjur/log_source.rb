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
  # This module provides logging support for actions taken by the Conjur API.
  #
  # @example
  #     class Example
  #       include LogSource
  #
  #       def something_interesting param
  #         log{|l| l << "doing something interesting with #{param}"}
  #
  #         # Do something interesting...
  #       end
  #
  #     end
  #     # ...
  #
  #     Example.new.something_interesting 'foo'
  #     # will log:
  #     # [admin] doing something interesting with foo
  #
  module LogSource
    # Yield a logger to the block.  You should use the `<<` method to write to the
    # logger so that you don't send newlines or formatting.  The block will only be called
    # if {Conjur.log} is not nil.
    #
    # The log format is `"[<username>]<messages logged in block>\n"`.
    #
    # @yieldparam [#<<] logger a logger to write messages
    # @return [void]
    def log(&block)
      if Conjur.log
        Conjur.log << "["
        Conjur.log << username
        Conjur.log << "] "
        yield Conjur.log
        Conjur.log << "\n"
      end
    end
  end
end