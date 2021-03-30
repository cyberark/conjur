module Authentication
  module AuthnAzure

    class XmsMirid

      REQUIRED_KEYS = %w[subscriptions resourcegroups providers].freeze

      def initialize(xms_mirid_token_field)
        @xms_mirid_token_field = xms_mirid_token_field

        @mirid_parts_hash = mirid_parts_hash
        validate
      end

      def subscriptions
        @mirid_parts_hash["subscriptions"].first
      end

      def resource_groups
        @mirid_parts_hash["resourcegroups"].first
      end

      def providers
        @mirid_parts_hash["providers"]
      end

      private

      # we expect the xms_mirid claim to be in the format of /subscriptions/<subscription-id>/...
      # therefore, we ignore the first slash of the xms_mirid claim and group the entries in key-value pairs
      # according to fields we need to retrieve from the claim.
      # ultimately, transforming "/key1/value1/key2/value2" to {"key1" => "value1", "key2" => "value2"}
      def mirid_parts_hash
        raw_mirid_parts = @xms_mirid_token_field.split('/')

        # accept also an xms_mirid field that doesn't start with a slash
        mirid_parts = if raw_mirid_parts.first == ''
          raw_mirid_parts.drop(1)
        else
          raw_mirid_parts
        end

        # transform ["subscriptions", "a", "resourcegroups", "b", "providers", "c", "d", "e"]
        # to {"subscriptions"=>["a"], "resourcegroups"=>["b"], "providers"=>["c", "d", "e"]}
        mirid_parts.slice_before(Regexp.new(REQUIRED_KEYS.join('|')))
          .map { |x| [x.first, x.drop(1)] }.to_h
      rescue => e
        # this should never occur, it's here to enhance supportability in case it does
        raise Errors::Authentication::AuthnAzure::XmsMiridParseError.new(
          @xms_mirid_token_field,
          e.inspect
        )
      end

      def validate
        missing_keys = REQUIRED_KEYS - @mirid_parts_hash.keys
        unless missing_keys.empty?
          raise Errors::Authentication::AuthnAzure::MissingRequiredFieldsInXmsMirid.new(
            missing_keys,
            @xms_mirid_token_field
          )
        end

        unless @mirid_parts_hash["providers"].length == 3
          raise Errors::Authentication::AuthnAzure::InvalidProviderFieldsInXmsMirid,
                @xms_mirid_token_field
        end
      end
    end
  end
end
