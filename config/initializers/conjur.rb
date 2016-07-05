def default_account
  ENV['CONJUR_ACCOUNT'] or raise "No CONJUR_ACCOUNT available"
end
