module ConjurAudit
  class Message < Sequel::Model
    dataset_module do
      def matching_sdata filter
        where Sequel[:sdata].pg_jsonb.contains filter
      end
    end
  end
end
