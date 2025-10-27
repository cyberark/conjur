# frozen_string_literal: true

require_relative '../../domain'

module EffectivePolicy
  module Pathing
    module UserPathing
      include Domain

      def user_full_id(res)
        "#{user_account_and_kind(res.resource_id)}:#{user_identifier(res)}"
      end

      def user_identifier(res)
        pol_identifier = policy_for_user(res)

        return "#{pol_identifier}/#{user_id(res.identifier)}" if not_root?(pol_identifier)

        owner_ats_identifier = "@#{identifier(res.owner_id).gsub('/', '@')}"
        if res.identifier.end_with?(owner_ats_identifier)
          user_without_owner = res.identifier[0...-owner_ats_identifier.length]
          return "#{owner_ats_identifier[1...]}/#{user_without_owner}"
        end

        res.identifier
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
end
