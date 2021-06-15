require 'command_class'

module Authentication
  module AuthnJwt
    module IdentityProviders
      # Add policy prefix to identity, for examples:
      # 1. Input: identity_prefix=host identity=host_test1
      #    Output: host/host_test1
      # 2. Input: identity_prefix=host/ identity=host_test1
      #    Output: host/host_test1
      # 3. Input: identity_prefix=host/ identity=/host_test1
      #    Output: host/host_test1
      # 4. Input: identity_prefix=host identity=/host_test1
      #    Output: host/host_test1
      AddPrefixToIdentity = CommandClass.new(
        dependencies: {
          logger: Rails.logger
        },
        inputs: %i[identity_prefix identity]
      ) do
        def call
          validate_input
          add_prefix_to_identity
        end

        private

        def validate_input
          validate_identity_exists
          validate_prefix_exists
        end

        def validate_identity_exists
          raise Errors::Authentication::AuthnJwt::MissingIdentity if @identity.blank?
        end

        def validate_prefix_exists
          raise Errors::Authentication::AuthnJwt::MissingIdentityPrefix if @identity_prefix.blank?
        end

        def add_prefix_to_identity
          @logger.debug(
            LogMessages::Authentication::AuthnJwt::AddingIdentityPrefixToIdentity.new(
              @identity_prefix,
              @identity
            )
          )

          identity_with_prefix
          @logger.debug(LogMessages::Authentication::AuthnJwt::AddedIdentityPrefixToIdentity.new(identity_with_prefix))
          identity_with_prefix
        end

        def identity_with_prefix
          @identity_with_prefix ||= identity_with_prefix_with_one_delimiter
        end

        def identity_with_prefix_with_one_delimiter
          @identity_with_prefix_with_one_delimiter ||= identity_prefix_with_delimiter_suffix + identity_without_delimiter_prefix
        end

        def identity_prefix_with_delimiter_suffix
          return @identity_prefix_with_character_suffix if @identity_prefix_with_character_suffix

          if identity_prefix_last_character != IDENTITY_PATH_CHARACTER_DELIMITER
            @identity_prefix_with_character_suffix = @identity_prefix + IDENTITY_PATH_CHARACTER_DELIMITER
          else
            @identity_prefix_with_character_suffix = @identity_prefix
          end

          @identity_prefix_with_character_suffix
        end

        def identity_prefix_last_character
          @identity_prefix_last_character ||= @identity_prefix[-1]
        end

        def identity_without_delimiter_prefix
          return @identity_without_delimiter_prefix if @identity_without_delimiter_prefix

          if identity_first_character == IDENTITY_PATH_CHARACTER_DELIMITER
            @identity_without_delimiter_prefix = identity_without_first_character
          else
            @identity_without_delimiter_prefix = @identity
          end

          @identity_without_delimiter_prefix
        end

        def identity_first_character
          @identity_first_character ||= @identity[0, 1]
        end

        def identity_without_first_character
          @identity[1..-1]
        end
      end
    end
  end
end
