Given(/^I fetch root certificate from https:\/\/([^"]*) endpoint as "([^"]*)"$/) do |hostname, key|
  fetch_and_store_root_certificate(hostname: hostname, key: key)
end

Given(/^I successfully set authn\-jwt "([^"]*)" variable value to the "([^"]*)" certificate$/) do |variable, key|
  create_jwt_secret(
    variable_name: variable,
    value: get_certificate_by_key(key: key)
  )
end

Given(/^I bundle the next certificates as "([^"]*)":$/) do |key, keys|
  bundle_certificates(keys: keys.split("\n"), key: key)
end
