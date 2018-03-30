Rails.application.routes.draw do

  mount AuthnLdap::Engine => "/authn_ldap"
end
