require 'sinatra'
require 'json'
require 'conjur/api'

get '/' do
  x = Conjur::API.authenticate_local('{"account":"cucumber", "sub":"cucumber:user:admin"}')
  puts 'x', x
  x.to_json
end

post '/api/authn-ldap/users/:user/authenticate' do
  # Something like this will always authenticate...
  #
  # Conjur::API.authenticate_local(params[:user])
  'hello'
end
