# frozen_string_literal: true

# Stores a text annotation on a resource.
class Annotation < Sequel::Model
  plugin :timestamps,         :update_on_create=>true
  plugin :validation_helpers
  
  unrestrict_primary_key
  
  many_to_one :resource, reciprocal: :annotations
  
  def as_json options = {}
    options[:except] ||= []
    options[:except].push(:resource_id)
    super(options).tap do |response|
      write_id_to_json(response, "policy")
    end
  end

  def self.find_annotation(account:, identifier:, name:, type:)
    annotation = Annotation.where(Sequel.lit('resource_id like ?', "#{account}:#{type}:%"))
    annotation = annotation.where(Sequel.lit('name = ?', name)) if name
    annotation.where(Sequel.lit('value = ?', identifier)).first
  end

  def validate
    super
    
    validates_presence([ :name, :value ])
  end
end