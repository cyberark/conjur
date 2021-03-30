$LOAD_PATH.unshift(File.expand_path('../../..', __FILE__))
require 'app/domain/repos/conjur_ca'

namespace :authn_k8s do
  desc "Initialize CA certificates for authn-k8s webservice"
  task :ca_init, [ "service-id" ] => :environment do |t, args|
    (service_name = args["service-id"]) || raise("usage: rake authn_k8s:ca_init[<service-id>]")
    # TODO: should be done in object
    service_id = "#{ENV['CONJUR_ACCOUNT']}:webservice:#{service_name}"

    Repos::ConjurCA.create(service_id)
    cert_resource = ::Conjur::CaInfo.new(service_id)

    puts "Populated CA and Key of service #{service_name}"
    puts "To print values:"
    puts " conjur variable value #{Resource[cert_resource.cert_id].identifier}"
    puts " conjur variable value #{Resource[cert_resource.key_id].identifier}"
  end
end
