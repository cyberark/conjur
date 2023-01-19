# frozen_string_literal: true

# TODO: This is needed because having the same line config/application.rb is
# not working.  I wasn't able to figure out what precisely was going wrong,
# even after discussing with Jeremy Evans (sequel's author) on IRC, but bottom
# line: without this line the extensions aren't loaded.
#
Sequel::Model.db.extension(:pg_hstore)

class PolicyLog < Sequel::Model :policy_log
  many_to_one :policy_version, key: %i(policy_id version)

  def to_audit_event
    Audit::Event::Policy.new(
      policy_version: policy_version,
      operation: operation,
      subject: event_subject
    )
  end

  def operation
    {
      'INSERT' => :add,
      'DELETE' => :remove,
      'UPDATE' => :change
    }[super]
  end

  def event_subject
    Audit::Subject.const_get(kind.singularize.camelize).new(
      subject.symbolize_keys
    )
  end
end
