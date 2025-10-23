# frozen_string_literal: true

module Branches
  class Branch
    extend(Domain)
    include Domain
    include Validation
    include ActiveModel::Validations

    validates :name, :branch, :owner,  presence: true
    validates :annotations, exclusion: { in: [nil], message: "cannot be nil" }
    validates :name, length: { minimum: NAME_LENGTH_MIN, maximum: NAME_LENGTH_MAX }
    validates :name, format: { with: NAME_PATTERN, message: NAME_PATTERN_MSG }
    validates :branch, :branch, presence: true
    validates :branch, length: { minimum: PATH_LENGTH_MIN }
    validates :branch, format: { with: PATH_PATTERN, message: PATH_PATTERN_MSG }
    validate :validate_branch_and_name

    attr_accessor :name, :branch, :owner, :annotations

    def initialize(name, branch, owner, annotations)
      @name = name
      @branch = branch
      @owner = owner
      @annotations = annotations

      raise DomainValidationError, errors.full_messages.to_sentence if invalid?
    end

    def to_s
      "#<Branch name=#{@name} branch=#{@branch} owner=#{@owner} annotations=#{@annotations}>"
    end

    def as_json(options = {})
      super(options).except("validation_context", "errors")
    end

    def self.from_input(input)
      owner = input[:owner] || {}
      annotations = input[:annotations] || {}

      new(input[:name],
          input[:branch],
          owner.empty? ? Owner.new : Owner.from_input(owner),
          Annotations::Annotations.from_input(annotations))
    end

    def self.from_model(model)
      new(res_name(model.identifier), # name
          parent_of(model.identifier), # branch
          Owner.from_model_id(model.owner_id), #owner
          Annotations::Annotations.from_model(model.annotations)) # annotations
    end

    def identifier
      to_identifier(@branch, @name)
    end

    private

    def validate_branch_and_name
      validate_identifier(to_identifier(@branch, @name)) unless @branch.nil? || @name.nil?
    end
  end
end
