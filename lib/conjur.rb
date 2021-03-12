require 'conjur/plugin'
require 'conjur/feature_flag'

module Conjur
  def self.feature_flag
    @feature_flag ||= FeatureFlag.new
  end
end
