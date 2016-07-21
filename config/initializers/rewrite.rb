Possum::Application.config.middleware.insert 0, Rack::Rewrite do
  rewrite %r{^/authn/users/(.*)}, '/authn/$1'
  rewrite %r{^/authz/([^\/]+)/resources(\?.*)?}, '/resources/$1$2'
  rewrite %r{^/authz/([^\/]+)/roles/allowed_to/([^\/]+)/([^?]*)(\?.*)?}, 'resources/$1/$3?permitted_roles&privilege=$2&$4'
  rewrite %r{^/authz/([^\/]+)/resources/(.*)}, '/resources/$1/$2'
  rewrite %r{^/authz/([^\/]+)/roles/(.*)},     '/roles/$1/$2'
end

Possum::Application.config.middleware.insert 0, Rack::Rewrite do
  rewrite %r{^/api/(.*)}, '/$1'
end
