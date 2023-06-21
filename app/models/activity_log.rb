class ActivityLog < Sequel::Model(:activity_log)
  def_column_alias :id, :activity_id
end