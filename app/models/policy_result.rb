# frozen_string_literal: true

# Contains Policy interpretation results.
# This is a structure of convenience, not elegance -- simply providing
# an uncomplicated package for moving policy results from one process
# to another.

class PolicyResult
  attr_reader :policy_version, :created_roles, :policy_parse

  def initialize(
    policy_version:,
    created_roles:,
    policy_parse:
  )
    @policy_version = policy_version
    @created_roles = created_roles
    @policy_parse = policy_parse
  end

  # Surface the parse error as the policy result error, in the future this
  # should probably return a collection of errors that include the parse and
  # load errors, rather than having the orchestrator raise those directly as
  # exceptions.
  def error
    @policy_parse.error
  end
end
