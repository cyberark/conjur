#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate a big policy for testing purposes

TAG_LEN = 5
NUM_VARS = 4 # per policy
NUM_APP = 50 # application policies per top level policy
NUM_TOPLEVEL = 2 # policies
NUM_USERS = 1000 # total
NUM_GROUPS = 100 # total

require 'ostruct'
require 'yaml'
require 'active_support'
require 'active_support/core_ext'

# generate a random alphanumeric tag
# (no attempt at uniqueness, adjust TAG_LEN or rerun on conflict)
def tag length = TAG_LEN
  alnum = [*?a..?z, *?0..?9].freeze
  length.times.map { alnum.sample }.join
end

module PolEncoder
  def encode_with c
    c.tag = self.class.name.downcase.prepend(?!)
    c.map = self.to_h.stringify_keys
  end
end

class Entity < OpenStruct
  include PolEncoder
  def initialize id = tag, **ka
    super(id: id, **ka)
  end
end

Group = Class.new(Entity)
Variable = Class.new(Entity)

class Policy < Entity
  def initialize *a
    super
    self.body = block_given? ? yield : []
  end
end

Allgroups = []

Permit = Struct.new(:role, :privilege, :resource)
Grant = Struct.new(:role, :member)
[Permit, Grant].each { |x| x.include(PolEncoder) }

def app_policy nvars = NUM_VARS
  Policy.new do
    vars = nvars.times.map { Variable.new }
    updaters = Group.new('updaters')
    fetchers = Group.new('fetchers')
    Allgroups << updaters << fetchers
    permits = [
      Permit.new(updaters, 'update', vars),
      Permit.new(fetchers, 'execute', vars)
    ]
    [
      *vars, updaters, fetchers, *permits, Grant.new(fetchers, updaters)
    ]
  end
end

def toplevel napp = NUM_APP
  Policy.new { napp.times.map { app_policy } }
end

toplevels = NUM_TOPLEVEL.times.map{toplevel}

User = Class.new(Entity)
users = NUM_USERS.times.map { User.new }
groups = NUM_GROUPS.times.map { Group.new }

# pick a random number usually =1 but occasionally higher
def pick
  Math.sqrt(1/rand).floor
end

# grant user to some groups
group_grants = users.map do |u|
  groups.shuffle.take(pick).map do |g|
    Grant.new(g, u)
  end
end.flatten

entitlements = groups.map do |g|
  Allgroups.shuffle.take(pick).map do |e|
    Grant.new(e, g)
  end
end.flatten

puts [*toplevels, *users, *groups, *group_grants, *entitlements].to_yaml

