
module ValidateScope
  extend ActiveSupport::Concern
  def validate_scope(limit, offset)
    if offset || limit
      # 'limit' must be an integer greater than 0 and less than 2000 if given
      if limit && (!numeric?(limit) || limit.to_i <= 0 || limit.to_i > 2000 )
        raise ArgumentError, "'limit' contains an invalid value. 'limit' must be a positive integer and less than 2000"
      end
      # 'offset' must be an integer greater than or equal to 0 if given
      if offset && (!numeric?(offset) || offset.to_i.negative?)
        raise ArgumentError, "'offset' contains an invalid value. 'offset' must be an integer greater than or equal to 0."
      end
    end
  end

  def numeric? val
    val == val.to_i.to_s
  end
end
