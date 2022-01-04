# frozen_string_literal: true

require 'openssl'
require 'socket'

# Utility methods for certificate manipulations
module CertsHelper

  def fetch_and_store_root_certificate(hostname:, key:)
    chain = get_certificate_chain(hostname)
    certs[key] = chain.find { |c| c.issuer == c.subject }.to_s
  end

  def get_certificate_by_key(key:)
    certs[key]
  end

  def bundle_certificates(keys:, key:)
    certs[key] = ""
    keys.each { |k| certs[key] += certs[k] }
  end

  private

  def certs
    @certs ||= {}
  end

  def get_certificate_chain(connect_hostname)
    host, port = connect_hostname.split(':')
    port ||= 443

    sock = TCPSocket.new(host, port.to_i)
    ssock = OpenSSL::SSL::SSLSocket.new(sock)
    ssock.hostname = host
    ssock.connect
    ssock.peer_cert_chain
  ensure
    ssock&.close
    sock&.close
  end

end

World(CertsHelper)
