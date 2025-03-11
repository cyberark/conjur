# frozen_string_literal: true

require_relative 'domain'
require_relative 'validation'

module Domain
  class Annotations < Hash
    include ActiveModel::Validations
    validates_with Validation::AnnotationsValidator

    def self.from_input(input)
      annotation = Annotations.new.merge(input)
      return annotation if annotation.valid?

      raise Domain::Validation::DomainValidationError, annotation.errors.full_messages.to_sentence
    end

    def self.from_model(model)
      model.each_with_object({}) { |m, result| result[m.name] = m.value }
    end
  end
end
