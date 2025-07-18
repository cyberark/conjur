# frozen_string_literal: true

require_relative '../domain'
require_relative '../validation'

module Domain
  class BranchUpPart
    extend(Domain)
    include Domain
    include Domain::Validation
    include ActiveModel::Validations

    validates :owner, exclusion: { in: [nil], message: "cannot be nil" }
    validates :annotations, exclusion: { in: [nil], message: "cannot be nil" }
    attr_accessor :owner, :annotations

    def initialize(owner, annotations)
      @owner = owner
      @annotations = annotations

      raise DomainValidationError, errors.full_messages.to_sentence if invalid?
    end

    def self.from_input(input)
      owner = input[:owner] || {}
      annotations = input[:annotations] || {}

      new(
        owner.empty? ? Owner.new : Owner.from_input(owner),
        Annotations.from_input(annotations)
      )
    end
  end
end
