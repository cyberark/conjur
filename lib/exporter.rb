# frozen_string_literal: true

require 'app/models/loader/orchestrate'
require 'app/domain/logs'
require 'app/models/policy_version'

class Exporter
  class << self
    def export
      puts policy_list.join("---\n")
    end

    private

    def policy_list
      PolicyVersion.all_current_policies.map do |policy|
         policy.working_policy_text
      end
    end
  end
end
