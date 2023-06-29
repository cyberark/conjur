module Presenter
  module PolicyFactory
    # returns an array representation to be used by the controller
    class Index
      def initialize(factories:)
        @factories = factories
      end

      def present
        {}.tap do |rtn|
          @factories
            .group_by(&:classification)
            .sort_by {|classification, _| classification }
            .map do |classification, factories|
              rtn[classification] = factories
                .map { |factory| factory_to_hash(factory) }
                .sort { |x, y| x[:name] <=> y[:name] }
            end
        end
      end

      private

      def factory_to_hash(factory)
        {
          name: factory.name,
          namespace: factory.classification,
          'full-name': "#{factory.classification}/#{factory.name}",
          'current-version': factory.version,
          description: factory.description || ''
        }
      end
    end
  end
end
