module Presenter
  module PolicyFactory
    # returns a hash representation to be used by the controller
    class Show
      def initialize(factory:)
        @factory = factory
      end

      def present
        {
          title: @factory.schema['title'],
          version: @factory.version,
          description: @factory.schema['description'],
          properties: @factory.schema['properties'],
          required: @factory.schema['required']
        }
      end
    end
  end
end
