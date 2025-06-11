# frozen_string_literal: true

# Contains Policy processing results.
# This is a structure of convenience, not elegance -- simply providing
# an uncomplicated package for moving policy results from one process
# to another.

class PolicyResult
  attr_accessor :policy_version, :created_roles, :policy_parse, :diff, :visible_resources_before, :visible_resources_after, :warnings

  def initialize(
    policy_version: nil,
    created_roles: nil,
    policy_parse: nil,
    diff: nil,
    visible_resources_before: nil,
    visible_resources_after: nil,
    warnings: nil
  )
    @policy_version = policy_version
    @created_roles = created_roles
    @policy_parse = policy_parse
    @diff = diff
    @visible_resources_before = visible_resources_before
    @visible_resources_after = visible_resources_after
    @warnings = warnings
  end

  # Allow individual setting of policy results as they are determined

  # Surface the parse error as the policy result error, in the future this
  # should probably return a collection of errors that include the parse and
  # load errors, rather than having the orchestrator raise those directly as
  # exceptions.
  def error
    @policy_parse.error
  end

  def error=(err)
    @policy_parse.error = err
  end
end
