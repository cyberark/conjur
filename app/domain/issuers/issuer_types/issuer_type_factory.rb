# frozen_string_literal: true

module Issuers
  module IssuerTypes
    class IssuerTypeFactory
      def create_issuer_type(type)
        if !type.nil? && type.casecmp("aws").zero?
          AwsIssuerType.new
        else
          raise ApplicationController::BadRequestWithBody, "issuer type is unsupported"
        end
      end
    end
  end
end
