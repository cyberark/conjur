require 'uri'
require 'net/http'
require 'nokogiri'
require 'pry'

uri = URI("https://keycloak:8443/auth/realms/master/protocol/openid-connect/auth?scope=email%20openid%20profile&state=aknsfasfkjn&response_type=code&client_id=conjurClient&redirect_uri=http%3A%2F%2Fconjur%3A3000%2Fauthn-oidc%2Fkeycloak2%2Fcucumber%2Fauthenticate&nonce=ljansfgoiub")
res = Net::HTTP.get_response(uri)
puts res.error if res.is_a?(Net::HTTPError)

all_cookies = res.get_fields('set-cookie')
cookies_arrays = Array.new
all_cookies.each do |cookie|
  cookies_arrays.push(cookie.split('; ')[0])
end

html = Nokogiri::HTML(res.body)
post_uri = URI(html.xpath('//form').first.attributes['action'].value)

http = Net::HTTP.new(post_uri.host, post_uri.port)
http.use_ssl = true
request = Net::HTTP::Post.new(post_uri.request_uri)
http.set_debug_output($stdout)
request['Cookie'] = cookies_arrays.join('; ')
request.set_form_data({'username' => 'alice', 'password' => 'alice'})

response = http.request(request)

if response.is_a?(Net::HTTPRedirection)
  location = URI(response['location'])

  http = Net::HTTP.new(location.host, location.port)
  http.set_debug_output($stdout)
  request = Net::HTTP::Post.new(location.request_uri)
  response = http.request(request)

  puts response.error if response.is_a?(Net::HTTPError)
end
