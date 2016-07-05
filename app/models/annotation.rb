# Stores a text annotation on a resource.
class Annotation < Sequel::Model
  plugin :timestamps,         :update_on_create=>true
  plugin :validation_helpers
  
  unrestrict_primary_key
  
  many_to_one :resource, reciprocal: :annotations
  
  def validate
    super
    
    validates_presence [ :name, :value ]
  end
end