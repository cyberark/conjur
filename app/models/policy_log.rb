# frozen_string_literal: true

Sequel::Model.db.extension(:pg_hstore)

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
    # p '&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&'
    # # require 'pry'
    # # binding.pry
    # # p Sequel
    # # p subject
    # p '&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&'
    # subj = Sequel::Postgres::HStore.parse(subject).to_h
    # k, v = subject.split('=>').map{ |x| x.gsub('"', '')}
    # subj = Hash[k.to_sym, v]
    # # TODO: remove this old code
    # Audit::Subject.const_get(kind.singularize.camelize).new(subj)
    Audit::Subject.const_get(kind.singularize.camelize).new subject.symbolize_keys
  end
end
