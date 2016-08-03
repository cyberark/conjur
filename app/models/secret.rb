# An encrypted secure value.
class Secret < Sequel::Model
  unrestrict_primary_key
  
  many_to_one :resource, reciprocal: :secrets
  
  attr_encrypted :value, aad: :resource_id
  
  class << self
    def latest_public_keys account, kind, id
      # Select the most recent value of each secret
      Secret.with(:max_values, 
        Secret.select(:resource_id){ max(:counter).as(:counter) }.
          natural_join(:resources).
          group_by(:resource_id).
          where("resource_id LIKE ?", "#{account}:public_key:#{kind}/#{id}/%")).
        natural_join(:max_values).
          all.
          map(&:value)
    end
  end

  def as_json options = {}
    super(options.merge(except: :value)).tap do |response|
      response["resource"] = response.delete("resource_id")
    end
  end

  
  def before_update
    raise Sequel::ValidationFailed, "Secret cannot be updated once created"
  end
  
  def validate
    super
    
    raise Sequel::ValidationFailed, "Value is not present" unless @values[:value]
  end
end
