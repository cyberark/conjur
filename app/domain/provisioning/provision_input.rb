# frozen_string_literal: true

require 'types'

module Provisioning
  class ProvisionInput < ::Dry::Struct
    attribute :provisioner_name, ::Types::NonEmptyString
    attribute :resource, ::Types::Any
    attribute :context, ::Types::Any
  end
end
