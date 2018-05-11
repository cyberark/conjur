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


   # WITH expired_secrets AS (SELECT resource_id FROM secrets GROUP BY resource_id HAVING max(expires_at) < NOW()) SELECT resource_id, value AS ttl FROM annotations NATURAL JOIN expired_secrets WHERE name = 'ttl'

# Album.group_and_count(:artist_id).having{count.function.* >= 10}
# # SELECT artist_id, count(*) AS count FROM albums
# # GROUP BY artist_id HAVING (count(*) >= 10)

    def freshly_expired
      Sequel::Model.db[<<-EOS
        SELECT resource_id, expires_at, value AS ttl
        FROM annotations
        NATURAL JOIN (
          SELECT max(expires_at) AS expires_at, resource_id 
          FROM secrets
          GROUP BY resource_id
          HAVING (
            max(expires_at) IS NULL OR max(expires_at) < NOW()
          )
        ) expired_secrets
        WHERE name = 'ttl'
      EOS
      ].all
    end
  end
      # Secret
      #   .join(:annotations, resource_id: :resource_id)
      #   .where{ expires_at < Sequel.function(:NOW) }
      #   .where( is_expired: false)
      #   .where( annotations__name: 'ttl')
      #   .select( :annotations__value )

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
