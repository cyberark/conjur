# frozen_string_literal: true

module HasId
  def account
    self.id.split(':')[0]
  end

  def kind
    self.id.split(':')[1]
  end

  def identifier
    self.id.split(':', 3)[2]
  end
end