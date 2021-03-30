# frozen_string_literal: true

# NOTE: the resulting encoding is a bit ugly
class Delegator
  def encode_with coder
    ivars = instance_variables.reject {|var| /\A@delegate_/ =~ var}
    coder['obj'] = __getobj__
    unless ivars.empty?
      coder['ivars'] = Hash[ivars.map{|var| [var[1..-1], instance_variable_get(var)]}]
    end
  end

  def init_with coder
    (coder['ivars'] || {}).each do |k, v|
      instance_variable_set(:"@#{k}", v)
    end
    __setobj__(coder['obj'])
  end
end
