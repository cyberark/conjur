# frozen_string_literal: true

# Removes persistence if Conjur is operating as a read-only instance
class Sequel::Model
  def before_save
    check_if_writes_permitted
    super
  end

  def before_destroy
    check_if_writes_permitted
    super
  end

  def check_if_writes_permitted
    return unless Rails.configuration.read_only

    raise ::Errors::Conjur::ReadOnly::ActionNotPermitted
  end
end
