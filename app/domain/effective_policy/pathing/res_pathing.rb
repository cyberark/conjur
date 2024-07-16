# frozen_string_literal: true

module EffectivePolicy
  module ResPathing

    def kind(res_full_id)
      res_full_id.split(":", 3)[1]
    end

    def policy?(kind)
      kind == 'policy'
    end

    def user?(kind)
      kind == 'user'
    end

    def identifier(res_full_id)
      # res_full_id - id from db: account:kind:identifier
      res_full_id.split(":", 3)[2]
    end
  end
end
