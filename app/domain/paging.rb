# frozen_string_literal: true

class Paging
  include Validation
  include ActiveModel::Validations

  PAGING_URL_PARAMS = %i[offset limit].freeze
  MAX_LIMIT = 1000
  DEFAULT_LIMIT_WHEN_OFFSET = 10

  attr_reader :offset, :limit

  validates :offset, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :limit, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: MAX_LIMIT }, allow_nil: true

  def initialize(input)
    @offset = parse_integer(input[:offset])
    @limit = parse_integer(input[:limit])

    validate_input!

    set_defaults
  end

  def limit?
    @limit > -1
  end

  def offset?
    @offset > -1
  end

  def to_s
    "#<Paging limit=#{@limit} offset=#{@offset}>"
  end

  private

  def parse_integer(value)
    value&.to_i
  end

  def validate_input!
    raise DomainValidationError, errors.full_messages.to_sentence if invalid?
  end

  def set_defaults
    @limit = determine_limit
    @offset = @offset.nil? ? -1 : @offset
  end

  def determine_limit
    return MAX_LIMIT if @limit.nil? && @offset.nil?

    @limit || DEFAULT_LIMIT_WHEN_OFFSET
  end
end
