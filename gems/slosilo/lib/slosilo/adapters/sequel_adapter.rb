require 'slosilo/adapters/abstract_adapter'

module Slosilo
  module Adapters
    class SequelAdapter < AbstractAdapter
      def model
        @model ||= create_model
      end

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
        attrs[:fingerprint] = value.fingerprint if fingerprint_in_db?
        model.create attrs
      end
      
      def get_key id
        stored = model[id]
        return nil unless stored
        Slosilo::Key.new stored.key
      end

      def get_by_fingerprint fp
        if fingerprint_in_db?
          stored = model[fingerprint: fp]
          return nil unless stored
          [Slosilo::Key.new(stored.key), stored.id]
        else
          warn "Please migrate to a new database schema using rake slosilo:migrate for efficient fingerprint lookups"
          find_by_fingerprint fp
        end
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

      private

      def fingerprint_in_db?
        model.columns.include? :fingerprint
      end

      def find_by_fingerprint fp
        each do |id, k|
          return [k, id] if k.fingerprint == fp
        end
      end
    end
  end
end
