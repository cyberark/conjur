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

    def id(str_id)
      last_slash_idx = str_id.rindex("/")
      last_slash_idx.nil? ? str_id : str_id[(last_slash_idx + 1)..]
    end

    def parent_identifier(identifier)
      last_slash_idx = identifier.rindex("/")
      last_slash_idx.nil? ? "" : identifier[0, last_slash_idx]
    end
  end
end
