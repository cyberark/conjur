# frozen_string_literal: true

def host_slosilo_key(account)
  Slosilo["authn:#{account}:host"]
end

def user_slosilo_key(account)
  Slosilo["authn:#{account}:user"]
end

def init_slosilo_keys(account)
  Slosilo["authn:#{account}:user"] ||= Slosilo::Key.new
  Slosilo["authn:#{account}:host"] ||= Slosilo::Key.new
end