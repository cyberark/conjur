module ConjurAudit
  class Message < Sequel::Model
    dataset_module do
      def matching_sdata filter
        where Filter.sdata filter
      end

      def matching_resource resource_id
        where Filter.resource resource_id
      end

      def matching_role role_id
        where Filter.role role_id
      end

      def matching_entity id
        where Filter.role(id) | Filter.resource(id)
      end
    end

    module Filter
      class << self
        def sdata filter
          Sequel[:sdata].pg_jsonb.contains filter
        end

        def resource id
          # all the places where a resource id can be
          [
            { 'subject@43868': { resource: id } },
            { 'policy@43868': { policy: id } },
            { 'auth@43868': { service: id } }
          ].map(&method(:sdata)).inject:|
        end

        def role id
          # all the places where a role id can be
          [
            { 'subject@43868': { role: id } },
            { 'subject@43868': { member: id } },
            { 'policy@43868': { policy: id } },
            { 'auth@43868': { user: id } }
          ].map(&method(:sdata)).inject:|
        end
      end
    end
  end
end
