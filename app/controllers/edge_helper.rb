# frozen_string_literal: true
module EdgeHelper
  def verify_edge_host(options)
    raise Forbidden unless %w[conjur cucumber rspec].include?(options[:account])
    raise Forbidden unless current_user.kind == 'host'
    raise Forbidden unless current_user.role_id.include?("host:edge/edge")
    role = Role[options[:account] + ':group:edge/edge-hosts']
    raise Forbidden unless role&.ancestor_of?(current_user)
  end
end