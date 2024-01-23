# frozen_string_literal: true

module Authentication
  module Util
    module V2
      class AuthenticatorLoader
        class << self
          def all
            {}.tap do |rtn|
              group_authenticators(authenticator_klasses).each do |authn_type, authn_klasses|
                next if authn_klasses[:strategy].nil? || authn_klasses[:authenticator].nil?

                rtn[authn_type] = authn_klasses
              end
            end
          end

          def authenticator_klasses
            results = []
            load_klasses(mod: Authentication, klasses: results)
            results.flatten.compact.uniq
          end

          private

          def group_authenticators(klasses)
            {}.tap do |grouped_files|
              klasses.each do |klass|
                parts = klass.to_s.split('::')
                next unless parts[1].match(/^Authn/)
                next unless parts[2] == 'V2'

                type = Authentication::Util::NamespaceSelector.module_to_type(parts[1])

                grouped_files[type] ||= {}
                case parts.last
                when 'Authenticator'
                  grouped_files[type][:authenticator] = klass
                when 'Strategy'
                  grouped_files[type][:strategy] = klass
                end
              end
            end
          end

          # Recursively loads all classes in the provided Module. This is
          # used to "auto-magically" find and use relevant authenticators.
          def load_klasses(mod:, klasses:)
            mod.constants.each do |constant|
              constant = mod.const_get(constant)
              case constant
              when Class
                klasses << constant
              when Module
                load_klasses(mod: constant, klasses: klasses)
              end
            end
          end
        end
      end

      # This is a utility to handle detection of Authenticator and Annotation
      # validations. This enables us to optionally add validations for a particular
      # authenticator.
      #
      class KlassLoader
        def initialize(type, namespace_selector: Authentication::Util::NamespaceSelector)
          @classified_type = namespace_selector.type_to_module(type)
        end

        def strategy
          find('Strategy')
        end

        def data_object
          find('DataObjects::Authenticator')
        end

        def authenticator_validation
          find('Validations::AuthenticatorConfiguration')
        end

        private

        def find(name)
          AuthenticatorLoader.authenticator_klasses.find { |klass| klass.name.match?("Authentication::#{@classified_type}::V2::#{name}") }
        end
      end
    end
  end
end
