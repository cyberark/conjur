# frozen_string_literal: true

module Domain

  def root_pol_id_pattern(identifier)
    "#{identifier == 'root' ? '%' : identifier}(|/%)"
  end

  def res_identifier(identifier)
    root?(identifier) ? 'root' : identifier&.sub(%r{^/}, "")
  end

  def domain_id(identifier)
    return '/' if root?(identifier)

    identifier.starts_with?('/') ? identifier : "/#{identifier}"
  end

  def to_identifier(parent_identifier, identifier)
    return identifier if root?(parent_identifier)

    "#{parent_identifier}/#{identifier}"
  end

  def full_id(account, kind, identifier)
    [account, kind, res_identifier(identifier)].join(":")
  end

  def account_of(full_id)
    full_id.split(":", 3)[0]
  end

  def kind(full_id)
    full_id.split(":", 3)[1]
  end

  def res_name(identifier)
    identifier.split('/').last
  end

  def parent_of(identifier)
    last_slash_idx = identifier.rindex("/")
    last_slash_idx ? identifier[0...last_slash_idx] : '/'
  end

  def identifier(id)
    id.split(":", 3)[2]
  end

  def root?(identifier)
    %w[/ /root root].include?(identifier)
  end

  def not_root?(identifier)
    !root?(identifier)
  end

  def policy?(kind)
    kind == 'policy'
  end
  #
  def user?(kind)
    kind == 'user'
  end
end
