module Authentication
  module AuthnJenkins
    class JenkinsClient
      def initialize(url, username, password)
        @url = url
        @username = username
        @password = password
      end
      
      def public_key()
        response = request('')
        create_public_key(response['X-Instance-Identity'])
      end
      
      def build(job, build_number)
        request("job/#{job}/#{build_number}/api/json")
      end
      
      private
      def create_public_key(identity)
        public_key = [
        "-----BEGIN PUBLIC KEY-----",
        identity,
        "-----END PUBLIC KEY-----"
        ].join("\n")
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
