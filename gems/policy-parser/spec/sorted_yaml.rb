require 'yaml'
require 'deepsort'

module SortedYAML
  def sorted_yaml yaml
    YAML.safe_load(yaml).deep_sort_by(&:to_s)
  end
end
