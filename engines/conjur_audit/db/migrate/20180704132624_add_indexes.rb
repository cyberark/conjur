# frozen_string_literal: true

Sequel.migration do
  change do
    add_index :messages, Sequel.desc(:timestamp)
    add_index :messages, :sdata, type: :gin, opclass: :jsonb_path_ops
  end
end
