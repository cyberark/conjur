module Rotation

  # Represents that policy variable that contains the rotator and ttl
  # annotations
  #
  class RotatedVariable
    attr_reader :resource_id, :ttl, :rotator_name

    def initialize(resource_id:, ttl:, rotator_name:)
      @resource_id = resource_id
      @ttl = ttl
      @rotator_name = rotator_name
    end

    def account
      @resource_id.split(':')[0]
    end

    def kind
      @resource_id.split(':')[1]
    end

    def name
      @resource_id.split(':', 3)[2]
    end

    def related_resource_id(name)
      prefix = @resource_id.match(%r{(.*)/.*})[1]
      "#{prefix}/#{name}"
    end
  end

end
