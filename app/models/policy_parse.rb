# frozen_string_literal: true

# Represents the results of parsing a policy from a YAML file --
# the records, or an error -- using Commands::Policy::Parse.

class PolicyParse
  attr_accessor :records, :error

  def initialize(records, error)
    @records = records
    @error = error
  end

  def create_records
    records.select do |r|
      !r.delete_statement?
    end
  end

  def delete_records
    records.select do |r|
      r.delete_statement?
    end
  end

  def reportable_error
    err = @error
    if err
      if err.instance_of?(Exceptions::EnhancedPolicyError)
        if err.original_error
          return err.original_error.to_s
        end
        
        return err.message
      end

      return err.to_s
    end

    nil
  end

end
