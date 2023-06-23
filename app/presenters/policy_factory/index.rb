module Presenter
  module PolicyFactory
    # returns an array representation to be used by the controller
    class Index
      def initialize(factories:)
        @factories = factories
      end

      def present
        @factories.map do |factory|
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
end
