# frozen_string_literal: true

module EffectivePolicy
  module UserPathing
    def user_full_id(res)
      "#{user_account_and_kind(res.resource_id)}:#{user_identifier(res)}"
    end

    def user_identifier(res)
      pol_identifier = policy_for_user(res)
      return user_id(res.identifier) if pol_identifier.empty?

      "#{policy_for_user(res)}/#{user_id(res.identifier)}"
    end

    def user_path(user_identifier)
      user_identifier.split('@', 2)[1]
    end

    def user_id(user_identifier)
      user_identifier.split('@', 2)[0]
    end

    def user_account_and_kind(full_id)
      last_slash_idx = full_id.rindex(":")
      full_id[0...last_slash_idx]
    end
  end
end
