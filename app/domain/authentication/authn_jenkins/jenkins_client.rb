module Authentication
  module AuthnJenkins
    class JenkinsClient
      Err = Errors::Authentication::AuthnJenkins
      def initialize(url, username, password, public_key, allow_http)
        @url = url
        @username = username
        @password = password
        @public_key = public_key
        if allow_http != 'true' && !@url.starts_with('https')
          raise Err::InvalidURL, @url
        end
      end
      
      def public_key()
        create_public_key
      end
      
      def build(job, build_number)
        request("job/#{job}/#{build_number}/api/json")
      end
      
      private
      def create_public_key()
        public_key = @public_key
        if !public_key.starts_with('-----BEGIN PUBLIC KEY-----') && !public_key.ends_with('-----END PUBLIC KEY-----')
          public_key = [
            "-----BEGIN PUBLIC KEY-----",
            identity,
            "-----END PUBLIC KEY-----"
            ].join("\n")
        end

        Rails.logger.debug("Returned public key: #{public_key}")
        OpenSSL::PKey::RSA.new(public_key)
      end
        
      def request(path)
        # Uses the HTTP gem: https://github.com/httprb/http
        begin
          HTTP.basic_auth(user: @username, pass: @password).get("#{@url}/#{path}")
        rescue Net::OpenTimeout => e
          Rails.logger.error("Timeout to Jenkins host Exception #{e}. Jenkins host '#{url}' is most likely invalid. Validate this url can be accessed from the conjur server.")
          raise Err::HostNotFound, url
        end
      end
    end
  end
end
