class PolicyLog < Sequel::Model :policy_log
  many_to_one :policy_version, key: %i(policy_id version)

  def to_audit_event
    Audit::Event::Policy.new \
      policy_version: policy_version,
      operation: operation,
      subject: event_subject
  end

  def operation
    {
      'INSERT' => :add,
      'DELETE' => :remove,
      'UPDATE' => :change
    }[super]
  end

  def event_subject
    Audit::Subject.const_get(kind.singularize.camelize).new subject.symbolize_keys
  end
end
