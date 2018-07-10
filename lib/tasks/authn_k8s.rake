namespace :authn_k8s do
  desc "Initialize CA certificates for authn-k8s webservice"
  task :ca_init, [ "service-id" ] => :environment do |t, args|
    service = args["service-id"] or raise "usage: rake authn_k8s:ca_init[<service-id>]"

    svc = AuthenticationService.new(service)
    svc.initialize_ca

    puts "Populated CA and Key of service #{service.inspect}"
    puts "To print values:"
    puts " conjur variable value #{svc.ca_cert_variable.id}"
    puts " conjur variable value #{svc.ca_key_variable.id}"
  end
end
