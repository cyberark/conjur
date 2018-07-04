# frozen_string_literal: true

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

    # resource_ids have form such as:
    #
    #     my_account:variable:some/resource/name
    #
    # Below are convenience methods for parsing those parts
    #
    def account
      @resource_id.split(':')[0]
    end

    def kind
      @resource_id.split(':')[1]
    end

    def name
      @resource_id.split(':', 3)[2]
    end

    # This assumes a single qualifying "prefix", eg:
    #
    #     my_account:variable:postgres/url
    #     my_account:variable:postgres/username
    #     my_account:variable:postgres/password
    #
    # and returns everything up to th first slash
    #
    def prefix
      @resource_id.match(%r{(.*)/.*})[1]
    end

    def sibling_id(name)
      "#{prefix}/#{name}"
    end
  end

end
