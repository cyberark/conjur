# frozen_string_literal: true

require 'kubeclient'
require 'uri'

# TODO: make it class that accepts env, so the validation is only done once
# That is, this is a really an object whose ctor dependency is ENV, and
# where the validation is done at construction.  `client` then becomes
# a method on that constructed object
#
module Authentication
  module AuthnK8s

    module KubeClientFactory

      def self.client(api: 'api', version: 'v1', host_url: nil, options: nil)
        full_url = "#{host_url}/#{api}"
        validate_host_url!(full_url)

        Kubeclient::Client.new(full_url, version, **options)
      end

      class << self
        private

        def validate_host_url! host_url
          raise if URI.parse(host_url).host.empty?
        rescue
          raise Errors::Authentication::AuthnK8s::InvalidApiUrl, host_url
        end
      end
    end
  end
end
