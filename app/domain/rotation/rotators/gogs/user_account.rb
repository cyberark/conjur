return if defined? Rotation::Rotators::Gogs::UserAccount

require 'rest-client'
require 'securerandom'

module Rotation
  module Rotators
    module Gogs
      class UserAccount
        def initialize()
        end

        def rotate(facade)
          variable_id = facade.rotated_variable.resource_id
          user_name = facade.annotations['gogs/user_name']
          base_url = facade.annotations['gogs/url']
          old_password = facade.current_values([variable_id])[variable_id]
          new_password = new_password(base_url, user_name, old_password)
          facade.update_variables({variable_id => new_password})
        end

        private

        def csrf_token(url, cookies={})
          response = RestClient.get(url, {cookies: cookies})
          csrf_rx = /<input.+?name="_csrf".+?value="(.+?)"/
          csrf_rx.match(response.body).captures.first
        end

        def auth_cookies(url, user_name, password, remember=false)
          token = csrf_token url
          begin
            RestClient.post(url,
                            {
                              _csrf: token,
                              user_name: user_name,
                              password: password,
                              remember: remember
                            })
          rescue RestClient::ExceptionWithResponse => e
            e.response.cookies
          end
        end

        def new_password(base_url,
                         user_name,
                         old_password,
                         new_password=SecureRandom.base64(32))
          cookies = auth_cookies("#{base_url}/user/login", user_name, old_password)
          token = csrf_token "#{base_url}/user/settings/password", cookies
          begin
            RestClient.post("#{base_url}/user/settings/password",
                            {
                              _csrf: token,
                              old_password: old_password,
                              password: new_password,
                              retype: new_password
                            },
                            {cookies: cookies})
          rescue RestClient::ExceptionWithResponse => e
            case e.response.code
            when 302
              new_password
            else
              raise e
            end
          end
        end
      end
    end
  end
end
