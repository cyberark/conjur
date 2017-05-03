# An encrypted secure value.
class Secret < Sequel::Model
  unrestrict_primary_key
  
  many_to_one :resource, reciprocal: :secrets
  
  attr_encrypted :value, aad: :resource_id
  
  class << self
    def latest_public_keys account, kind, id
      # Select the most recent value of each secret
      Secret.with(:max_values, 
        Secret.select(:resource_id){ max(:version).as(:version) }.
          group_by(:resource_id).
          where("account(resource_id)".lit => account).
          where("kind(resource_id)".lit => 'public_key').
          where(Sequel.like("identifier(resource_id)".lit, "#{kind}/#{id}/%"))).
        join(:max_values, [ :resource_id, :version ]).
          order(:resource_id).
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
