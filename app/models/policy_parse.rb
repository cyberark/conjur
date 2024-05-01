# frozen_string_literal: true

# Represents the results of parsing a policy from a YAML file --
# the records, or an error -- using Conjur::PolicyParser.

class PolicyParse
  attr_reader :records, :error

  def initialize(records, error)
    @records = records
    @error = error
  end

end
