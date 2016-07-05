module Sequel
  module Plugins
    module JsonIdSerializer
      module InstanceMethods

        def as_json options = {}
          hash = self.to_hash.clone
          self.class.associations.each do |k|
            next if Array(options[:exclude]).member?(k.to_sym)
            assobj = send(k)
            if assobj.nil?
              # Hit the DB to try again and find the association.
              assobj = send(k, true)
            end
            if assobj.respond_to? :id
              hash.delete "#{k}_id".to_sym
              hash[k] = assobj.id
            end
          end
          hash.stringify_keys
        end

      end
    end
  end
end
