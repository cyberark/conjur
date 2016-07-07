# Stores a text annotation on a resource.
class Annotation < Sequel::Model
  plugin :timestamps,         :update_on_create=>true
  plugin :validation_helpers
  
  unrestrict_primary_key
  
  many_to_one :resource, reciprocal: :annotations
  
  def as_json options = {}
    options[:except] ||= []
    options[:except].push :resource_id
    super options
  end

  def validate
    super
    
    validates_presence [ :name, :value ]
  end
end