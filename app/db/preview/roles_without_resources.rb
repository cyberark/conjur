module DB
  module Preview
    class RolesWithoutResources
      def call
        item_ids = gather_data
        if item_ids.count > 0
          puts("\nRoles and resources that will be removed because the parent policy has been removed")
          
          max_id = item_ids.map { |id| id.split(":", 3)[2] }.max_by(&:length).length
          printf("%-#{max_id}s %s\n", "ID", "TYPE")
          item_ids.sort_by { |id| id.split(":", 3)[2] }.each do |id|
            printf("%-#{max_id}s %s\n", id.split(":", 3)[2], id.split(":", 3)[1])
          end
        else
          printf("\nNo items to remove\n")
        end
      end

      def gather_data
        role_ids = Role
          .where(Sequel.lit('policy_id is not null AND role_id not in (select resource_id from resources)'))
          .all
          .map(&:role_id)
        
        role_ids.each do |id|
          role_ids += get_recursive_role_ids(id, 1)
        end

        Resource.where(owner_id: role_ids).all.map(&:resource_id) | role_ids
      end

      def get_recursive_role_ids(role_id, iterator)
        if iterator > 100
          raise "Recursion limit reached"
        end

        role_ids = Role
          .where(Sequel.lit('EXISTS (SELECT 1 FROM resources WHERE owner_id = ? AND resource_id = role_id)', role_id))
          .all
          .map(&:role_id)
        
        role_ids.each do |id|
          role_ids += get_recursive_role_ids(id, iterator+1)
        end

        role_ids
      end
    end
  end
end