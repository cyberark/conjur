# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :annotations do
      foreign_key :resource_id, :resources, type: String, null: false, on_delete: :cascade
      String :name, text: true, null: false
      String :value, text: true, null: false
      
      primary_key [:resource_id, :name]
      
      index [:name], name: :annotations_name_index
    end
  end
end
