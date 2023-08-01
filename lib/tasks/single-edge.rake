require_relative '../../app/db/preview/single_edge_to_multi'
#TODO: delete once single edge users are migrated to multi
namespace :db do
  desc "Migrate single edge to multi"
  task :"single-to-multi", [] => [:environment] do |t, args|
    single_host_id = ::DB::Preview::SingleEdgeToMulti.new.find_single_host_id
    if single_host_id
      Edge.dataset.insert_conflict(target: [:name]).insert({name: "Edge_01", id: single_host_id, version: "1.0.2", platform: "Podman"})
    end
  end
end