require 'yaml'
require 'deepsort'

module SortedYAML
  def sorted_yaml yaml
    YAML.load(yaml).deep_sort_by {|obj| obj.to_s}
  end
end
