# frozen_string_literal: true
require_relative '../../app/models/schemata'

Sequel.migration do
  up do
    execute Functions.create_authn_ann_trigger_sql(Schemata.new.primary_schema)
  end
  
  down do
    execute Functions.drop_authn_anno_trigger_sql
  end
end
