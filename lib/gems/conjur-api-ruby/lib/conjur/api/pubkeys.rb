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

  class API
    class << self
      # @!group Public Keys

      # Fetch *all*  public keys for the user.  This method returns a newline delimited
      # String for compatibility with the authorized_keys SSH format.
      #
      #
      # If the given user does not exist, an empty String will be returned.  This is to prevent attackers from determining whether
      # a user exists.
      #
      # ## Permissions
      # You do not need any special permissions to call this method, since public keys are, well, public.
      #
      #
      # @example
      #   puts api.public_keys('jon')
      #   # ssh-rsa [big long string] jon@albert
      #   # ssh-rsa [big long string] jon@conjurops
      #
      # @param [String] username the *unqualified* Conjur username
      # @return [String] newline delimited public keys
      def public_keys username, account: Conjur.configuration.account
        url_for(:public_keys_for_user, account, username).get
      end

      #@!endgroup
    end
  end
end
