require "rack/jekyll"

if site_password = ENV['SITE_PASSWORD']
  use Rack::Auth::Basic, "Restricted Area" do |username, password|
    [username, password] == ['admin', site_password]
  end
end

run Rack::Jekyll.new
