# frozen_string_literal: true

require 'app/models/loader/orchestrate'
require 'app/domain/logs'
require 'app/models/policy_version'

class Exporter
  class << self
    def export
      Sequel::Model.db.transaction do
        puts PolicyVersion.all
      end
    end
  end
end
