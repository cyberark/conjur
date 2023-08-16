# frozen_string_literal: true

# Stores a text annotation on a resource.
class Annotation < Sequel::Model
  plugin :timestamps,         :update_on_create=>true
  plugin :validation_helpers
  
  unrestrict_primary_key
  
  many_to_one :resource, reciprocal: :annotations
  many_to_one :role, :key => :role_id, :class => :Role
  def as_json options = {}
    options[:except] ||= []
    options[:except].push(:resource_id)
    super(options).tap do |response|
      write_id_to_json(response, "policy")
    end
  end

  def validate
    super
    
    validates_presence([ :name, :value ])
  end
end