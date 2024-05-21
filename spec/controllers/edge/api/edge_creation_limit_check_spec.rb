# frozen_string_literal: true
require 'spec_helper'

describe EdgeCreationController, :type => :request do

  context "Limit check" do

    after do
      Sequel::Model.db.transaction do
        Sequel::Model.db.execute("LOCK TABLE edges IN ACCESS EXCLUSIVE MODE")
        Sequel::Model.db.execute("TRUNCATE edges")
        Sequel::Model.db.execute("COMMIT")
      end
    end

    it "exceed max edge" do
      number_try_to_create = 20
      max_allowed = number_try_to_create-5
      #threads = []
      number_try_to_create.times do |i|
        # to check same time access remove the comment from threads. suggest do it for single run
        #threads << Thread.new do
          attempt = 0
          begin
            attempt += 1
            Sequel::Model.db.transaction do
                Edge.new_edge(max_edges: max_allowed, name: "edgy" + i.to_s, id: i, version: "1.1.1", platform: "podman", installation_date: Time.at(111111111), last_sync: Time.at(222222222))
            end
          rescue => e
            if not e.message == "Edge number exceeded max edge allowed #{max_allowed}" and attempt < 10
              retry
            end
          end
        end
      #end
      #threads.each(&:join)
      expect(Edge.count).to eq(max_allowed)
    end
  end

end

