if default_account = ENV['CONJUR_ACCOUNT']
  $stderr.puts "Activating v4 route compatibility with account '#{default_account}'"
  Rails.application.config.middleware.insert_before(Rack::Runtime, Rack::Rewrite) do
    rewrite %r{/authn/users/([^/]*)/authenticate}, "/authn/#{default_account}/$1/authenticate", method: :post
    rewrite %r{/variables/([^/]*)/value}, "/secrets/#{default_account}/variable/$1", method: :get
  end
end
