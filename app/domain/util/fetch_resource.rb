module Util
  FetchResource = CommandClass.new(
    dependencies: {
      resource_class: ::Resource
    },
    inputs: %i[resource_id]
  ) do
    def call
      resource
    end

    private

    def resource
      @resource_class[@resource_id]
    end
  end
end
