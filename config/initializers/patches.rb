# frozen_string_literal: true

class TrueClass
  def to_bool
    self
  end
end

class FalseClass
  def to_bool
    self
  end
end

class String
  def to_bool
    case self.downcase
    when 'n', 'no', 'f', 'false', 'nay', '', 'off', '0'
      false
    else true
    end
  end
end
