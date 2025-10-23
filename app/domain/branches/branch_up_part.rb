# frozen_string_literal: true

module Branches
  class BranchUpPart
    include Domain
    include Validation
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
        owner.empty? ? Branches::Owner.new : Branches::Owner.from_input(owner),
        Annotations::Annotations.from_input(annotations)
      )
    end
  end
end
