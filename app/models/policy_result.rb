# frozen_string_literal: true

# Contains Policy processing results.
# This is a structure of convenience, not elegance -- simply providing
# an uncomplicated package for moving policy results from one process
# to another.

class PolicyResult
  attr_reader :policy_version, :created_roles, :policy_parse, :diff

  def initialize(
    policy_version: nil,
    created_roles: nil,
    policy_parse: nil,
    diff: nil
      )
    @policy_version = policy_version
    @created_roles = created_roles
    @policy_parse = policy_parse
    @diff = diff
  end

  # Allow individual setting of policy results as they are determined
  def policy_version=(version)
    @policy_version = version
  end

  def created_roles=(roles)
    @created_roles = roles
  end

  def policy_parse=(parse)
    @policy_parse = parse
  end

  def diff=(diff)
    @diff = diff
  end

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
