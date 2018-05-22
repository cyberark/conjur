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

    def scheduled_rotations
      Sequel::Model.db[<<-EOS
        SELECT ttl.resource_id, ttl.value AS ttl, rotators.value AS rotator_name
        FROM annotations ttl
        -- This ensures we get only entries with both
        -- a ttl and a rotator specified
        JOIN annotations rotators ON (
          rotators.resource_id = ttl.resource_id
          AND rotators.name = 'rotator'
        )
        LEFT JOIN (
          SELECT resource_id, MAX(expires_at) AS expires_at
          FROM secrets
          GROUP BY resource_id
        ) e ON ttl.resource_id = e.resource_id
        WHERE ttl.name = 'ttl' 
        AND (
          e.expires_at < NOW() OR e.expires_at IS NULL
        )
      EOS
      ].all
    end

    # TODO optimize
    #
    def latest_resource_values(resource_ids)
      # Equivalent query in pure SQL
      #
      # query = <<-EOS
      #   SELECT t.resource_id, t.version, t.value
      #   FROM secrets t
      #   JOIN (
      #     SELECT resource_id, MAX(version) AS version
      #     FROM secrets
      #     GROUP BY resource_id
      #   ) max_versions ON (
      #     max_versions.resource_id = t.resource_id
      #     AND max_versions.version = t.version
      #   )
      #   WHERE t.resource_id IN ?
      # EOS
      # Sequel::Model.db[query, resource_ids]

      max_versions = Secret
        .select_group(:resource_id)
        .select_append{ max(:version).as(:version) }

      Secret
        .join(max_versions.as(:max_versions),
              :resource_id => :resource_id,
              :version => :version)
        .where(Sequel[:secrets][:resource_id] => resource_ids)
        .select(Sequel[:secrets][:resource_id],
                Sequel[:secrets][:value])
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
