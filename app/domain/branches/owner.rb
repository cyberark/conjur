# frozen_string_literal: true

module Branches
  class Owner
    include ActiveModel::Validations
    include Validation

    OWNER_KINDS = %w[host user group policy].freeze
    OWNER_KINDS_MSG = "'%{value}' is not a valid owner kind"

    validates :kind, presence: true, inclusion: { in: OWNER_KINDS, message: OWNER_KINDS_MSG }
    validates :id, presence: true, format: { with: USER_PATH_PATTERN, message: USER_PATH_PATTERN_MSG }, if: -> { kind == 'user' }
    validates :id, presence: true, format: { with: PATH_PATTERN, message: PATH_PATTERN_MSG }, unless: -> { kind == 'user' }
    validates :id, length: { minimum: PATH_LENGTH_MIN, maximum: PATH_LENGTH_MAX }
    validate :validate_id

    extend(Domain)
    attr_reader :kind, :id

    def initialize(kind = '', id = '', is_set: false)
      @kind = kind
      @id = id
      @is_set = is_set

      raise DomainValidationError, errors.full_messages.to_sentence if set? && invalid?
    end

    def set?
      @is_set
    end

    def self.from_input(input)
      new(input[:kind], input[:id], is_set: true)
    end

    def self.from_model_id(owner_id)
      new(kind(owner_id), identifier(owner_id), is_set: true)
    end

    def as_json(options = {})
      super(options).except("validation_context", "errors", "is_set")
    end

    def not_admin?
      @id != 'admin' || @kind != 'user'
    end

    def to_s
      "#<Owner kind=#{@kind} id=#{@id} set=#{@is_set}>"
    end

    private

    def validate_id
      validate_identifier(@id) if @kind != 'user'
    end
  end
end
