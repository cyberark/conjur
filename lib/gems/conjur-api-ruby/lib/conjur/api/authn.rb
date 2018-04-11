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
require 'conjur/user'

module Conjur
  class API
    class << self
      #@!group Authentication

      # Exchanges a username and a password for an api key.  The api key
      #   is preferable for storage and use in code, as it can be rotated and has far greater entropy than
      #   a user memorizable password.
      #
      #  * Note that this method works only for {Conjur::User}s. While
      #   {Conjur::Host}s are roles, they do not have passwords.
      #  * If you pass an api key to this method instead of a password, it will verify and return the API key.
      #  * This method uses HTTP Basic Authentication to send the credentials.
      #
      # @example
      #   bob_api_key = Conjur::API.login('bob', 'bob_password')
      #   bob_api_key == Conjur::API.login('bob', bob_api_key)  # => true
      #
      # @param [String] username The `username` or `login` for the
      #   {http://developer.conjur.net/reference/services/directory/user Conjur User}.
      # @param [String] password The `password` or `api key` to authenticate with.
      # @param [String] account The organization account.
      # @return [String] the API key.
      def login username, password, account: Conjur.configuration.account
        if Conjur.log
          Conjur.log << "Logging in #{username} to account #{account} via Basic authentication\n"
        end
        url_for(:authn_login, account, username, password).get
      end

      # Exchanges Conjur the API key (refresh token) for an access token.  The access token can 
      # then be used to authenticate further API calls.
      #
      # @param [String] username The username or host id for which we want a token
      # @param [String] api_key The api key
      # @param [String] account The organization account.
      # @return [String] A JSON formatted authentication token.
      def authenticate username, api_key, account: Conjur.configuration.account
        account ||= Conjur.configuration.account
        if Conjur.log
          Conjur.log << "Authenticating #{username} to account #{account}\n"
        end
        JSON.parse url_for(:authn_authenticate, account, username).post(api_key, content_type: 'text/plain')
      end

      # Obtains an access token from the +authn_local+ service. The access token can 
      # then be used to authenticate further API calls.
      #
      # @param [String] username The username or host id for which we want a token
      # @param [String] account The organization account.
      # @return [String] A JSON formatted authentication token.
      def authenticate_local username, account: Conjur.configuration.account, expiration: nil, cidr: nil, service_id: nil, authn_type: nil
        account ||= Conjur.configuration.account
        if Conjur.log
          Conjur.log << "Authenticating #{username} to account #{account} using authn_local\n"
        end

        require 'json'
        require 'socket'
        message = url_for(:authn_authenticate_local, username, account, expiration, cidr, service_id, authn_type)
        JSON.parse(UNIXSocket.open(Conjur.configuration.authn_local_socket) {|s| s.puts message; s.gets })        
      end

      # Change a user's password.  To do this, you must have the user's current password.  This does not change or rotate
      #   api keys. However, you *can* use the user's api key as the *current* password, if the user was not created
      #   with a password.
      #
      # @param [String] username the name of the user whose password we want to change.
      # @param [String] password the user's *current* password *or* api key.
      # @param [String] new_password the new password for the user.
      # @param [String] account The organization account.
      # @return [void]
      def update_password username, password, new_password, account: Conjur.configuration.account
        if Conjur.log
          Conjur.log << "Updating password for #{username} in account #{account}\n"
        end
        url_for(:authn_update_password, account, username, password).put new_password
      end

      #@!endgroup

      #@!group Password and API key management

      # Rotate the currently authenticated user or host API key by generating and returning a new one.
      # The old API key is no longer valid after calling this method.  You must have the current
      # API key or password to perform this operation.  This method *does not* affect a user's password.
      #
      # @param [String] username the name of the user or host whose API key we want to change
      # @param [String] password the user's current api key
      # @param [String] account The organization account.
      # @return [String] the new API key
      def rotate_api_key username, password, account: Conjur.configuration.account
        if Conjur.log
          Conjur.log << "Rotating API key for self (#{username} in account #{account})\n"
        end

        url_for(:authn_rotate_own_api_key, account, username, password).put('').body
      end

      #@!endgroup
    end
  end
end
