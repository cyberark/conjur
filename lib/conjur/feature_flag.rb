module Conjur
  class FeatureFlag
    def gem_plugins?
      ENV['CONJUR_FEATURE_PLUGINS_ENABLED'].casecmp?('true')
    end
  end
end
