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
require 'logger'

module Conjur
  # Assign a Logger for use by Conjur API methods.  This method accepts
  # several argument forms:
  # * The strings 'stdout' and 'stderr' cause log messages to be sent to the corresponding stream.
  # * Other stings are treated as paths and will cause log messages to be sent to those files.
  # * A `Logger` instance will be used as is.
  #
  # Note that the logger specified by the `CONJURAPI_LOG` environment variable will override
  # the value set here.
  #
  # @param [String, Logger,nil] log the new logger to use
  # @return [void]
  def self.log= log
    @@log = create_log log
  end

  # @api private
  # Create a log from a String or Logger param
  #
  # @param [String, Logger, nil] param the value to create the logger from
  # @return Logger
  def self.create_log param
    if param
      if param.is_a? String
        if param == 'stdout'
          Logger.new $stdout
        elsif param == 'stderr'
          Logger.new $stderr
        else
          Logger.new param
        end
      else
        param
      end
    end
  end

  @@env_log = create_log ENV['CONJURAPI_LOG']

  @@log = nil

  # @api private
  # @note this method may return nil if no log has been set, so you **must** check the value
  # before attempting to use the logger.
  #
  # You should consider using {Conjur::LogSource} instead.
  def self.log
    @@env_log || @@log
  end
end