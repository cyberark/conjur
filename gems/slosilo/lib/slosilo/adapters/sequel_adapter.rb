require 'slosilo/adapters/abstract_adapter'

module Slosilo
  module Adapters
    class SequelAdapter < AbstractAdapter
      def model
        @model ||= create_model
      end

      FINGERPRINT_SEPARATOR = "|||||||id:"

      def secure?
        !Slosilo.encryption_key.nil?
      end

      def create_model
        model = Sequel::Model(:slosilo_keystore)
        model.unrestrict_primary_key
        model.attr_encrypted(:key, aad: :id) if secure?
        model
      end

      def put_key id, value
        fail Error::InsecureKeyStorage unless secure? || !value.private?

        attrs = { id: id, key: value.to_der }
        attrs[:fingerprint] = value.fingerprint
        stored = model[id]
        if stored
          stored_redis = stored
          stored.update attrs
          Rails.cache.delete("slosilo/#{stored_redis.fingerprint}")
        else
          model.create attrs
        end
        fingerprint_value = "#{attrs[:key]}#{FINGERPRINT_SEPARATOR}#{attrs[:id]}"
        write_redis_slosilo(id, attrs[:key])
        write_redis_slosilo("#{attrs[:fingerprint]}", fingerprint_value)
      end

      def get_key id
        stored = get_redis_slosilo(id)
        if stored.nil?
          stored_db = model[id]
          unless stored_db.nil?
            write_redis_slosilo(id, stored_db.key)
            return Slosilo::Key.new stored_db.key
          end
          return nil
        end
        return Slosilo::Key.new stored
      end

      def get_by_fingerprint fp
        stored_in_redis = get_redis_slosilo(fp)
        if stored_in_redis.nil?
          stored_in_db = model[fingerprint: fp]
          unless stored_in_db.nil?
            slosilo = "#{stored_in_db.key}#{FINGERPRINT_SEPARATOR}#{stored_in_db.id}"
            write_redis_slosilo(fp, slosilo)
            return [Slosilo::Key.new(stored_in_db.key), stored_in_db.id]
          end
          return nil
        end
        stored =  stored_in_redis.split(FINGERPRINT_SEPARATOR)
        return [Slosilo::Key.new(stored[0]), stored[1]]
      end

      def each
        model.each do |m|
          yield m.id, Slosilo::Key.new(m.key)
        end
      end

      def recalculate_fingerprints
        # Use a transaction to ensure that all fingerprints are updated together. If any update fails,
        # we want to rollback all updates.
        model.db.transaction do
          model.each do |m|
            m.update fingerprint: Slosilo::Key.new(m.key).fingerprint
          end
        end
      end

      def migrate!
        unless fingerprint_in_db?
          model.db.transaction do
            model.db.alter_table :slosilo_keystore do
              add_column :fingerprint, String
            end

            # reload the schema
            model.set_dataset model.dataset

            recalculate_fingerprints

            model.db.alter_table :slosilo_keystore do
              set_column_not_null :fingerprint
              add_unique_constraint :fingerprint
            end
          end
        end
      end

      OK = 'OK'
      def write_redis_slosilo(id, value)
        return OK unless redis_configured?
        begin
          Rails.logger.debug{LogMessages::Redis::RedisAccessStart.new('Write')}
          redis_id = "slosilo/#{id}"
          response = Slosilo::EncryptedAttributes.encrypt(value, aad: redis_id)
                                                 .yield_self { |val| Rails.cache.write(redis_id, val) }
          Rails.logger.debug{LogMessages::Redis::RedisAccessEnd.new('Write', "Successfully wrote slosilo key for #{id} with response #{response}")}
        rescue Exception => e
          Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Write', e.message))
        end
      end


      def redis_configured?
        Rails.configuration.cache_store.include?(:redis_cache_store)
      end
      def get_redis_slosilo(id)
        return nil unless redis_configured?
        begin
          Rails.logger.debug{LogMessages::Redis::RedisAccessStart.new('Read')}
          redis_id = "slosilo/#{id}"
          stored = Rails.cache.read(redis_id)&.
            yield_self { |res| Slosilo::EncryptedAttributes.decrypt(res, aad: redis_id) }
          Rails.logger.debug{LogMessages::Redis::RedisAccessEnd.new('Read', "Successfully read slosilo key for #{id}")}
        rescue Exception => e
          Rails.logger.error(LogMessages::Redis::RedisAccessFailure.new('Read', e.message))
          return nil
        end
        stored
      end

    end

  end
end
