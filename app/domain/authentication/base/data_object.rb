# frozen_string_literal: true

module Authentication
  module Base
    class DataObject
      attr_reader(:account, :service_id)

      def initialize(account:, service_id: nil)
        @account = account
        @service_id = service_id
      end

      def type
        @type ||= self.class.to_s.split('::')[1].underscore.dasherize
      end

      def identifier
        [type, @service_id].compact.join('/')
      end

      def resource_id
        [
          @account,
          'webservice',
          [
            'conjur',
            type,
            @service_id
          ].compact.join('/')
        ].join(':')
      end

      def variable_prefix
        "#{@account}:variable:conjur/#{identifier}"
      end

      def token_ttl
        return ActiveSupport::Duration.parse(@token_ttl.to_s).to_i if @token_ttl.to_s.present?

        # If token TTL has not been set on the authenticator, return nil so that it
        # can be set using the configured user/host TTL values downstream.
        nil
      rescue ActiveSupport::Duration::ISO8601Parser::ParsingError
        raise Errors::Authentication::DataObjects::InvalidTokenTTL.new(resource_id, @token_ttl)
      end

      # TODO: required once role annotation check is implemented for authn-jwt.
      #
      # def annotations_required
      #   requires_role_annotations = self.class::REQUIRES_ROLE_ANNOTIONS
      #   return requires_role_annotations unless requires_role_annotations.nil?

      #   raise "class constant 'REQUIRES_ROLED_ANNOTIONS' must be defined"
      # end
    end
  end
end
