#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate random log data, copying it directly into the database.

# We care about general distribution of various kinds of messages,
# ie. the shape of the data as perceived by the pg optimizer.
# We don't care about consistency of the resulting log data.
# We don't entirely care if it entirely conforms to the audit log format,
# specifically if the messages and sdata are complete.

COUNT = (ARGV[0] || 10000).to_i

# scale number of unique users & resources proportionally to the event count
TAG_LEN = [(Math.log(COUNT) / Math.log(36) - 2).ceil, 1].max

require 'weighted_randomizer'
require 'sequel'
require 'pg'

require 'syslog'

DB = Sequel.connect(ENV['DATABASE_URL'])

def tag length = TAG_LEN
  alnum = [*"a".."z", *"0".."9"].freeze
  Array.new(length) { alnum.sample }.join
end

# :reek:ControlParameter
def info_warn success
  success ? Syslog::LOG_INFO : Syslog::LOG_WARNING
end

# Generates audit log entries.
# When enumerated, returns entried in PG text format,
# with columns defined in COLUMNS.
class Generator
  include Enumerable

  TIMESPAN = (Time.now - 42 * 24 * 60 * 60)..Time.now

  MESSAGE_IDS = 
    WeightedRandomizer.new(\
      authn: 211,
      check: 100,
      fetch: 100,
      # policy messages are rare, ignore
      update: 10
    )

  COLUMNS = %i[facility timestamp msgid hostname appname severity sdata procid message].freeze

  def each
    COUNT.times.lazy.each { yield(generate.join("\t") + "\n") }
  end
  
  def generate
    random_message.values_at(*COLUMNS)
  end
  
  def random_message
    msgid = MESSAGE_IDS.sample
    defaults(msgid: msgid).merge(send(msgid))
  end
  
  def defaults **kargs
    kargs.merge(\
      timestamp: timestamp, 
      facility: Syslog::LOG_AUTH >> 3,
      hostname: 'conjur.example',
      appname: 'conjur',
      severity: Syslog::LOG_INFO,
      sdata: 'null',
      procid: tag(10)
    )
  end
  
  SUCCESS = WeightedRandomizer.new(\
    true => 10,
    false => 1
  )

  def authn
    success = SUCCESS.sample
    user = "a:u:#{tag}"
    {
      sdata: {
        'subject@43868': {
          user: user
        }
      }.to_json,
      message: "#{user} a: #{success}", # doesn't need to be correct
      facility: Syslog::LOG_AUTHPRIV >> 3,
      severity: info_warn(success)
    }
  end
  
  def check
    success = SUCCESS.sample
    {
      sdata: {
        'subject@43868': {
          resource: (variable = "a:v:#{tag}"),
          privilege: (privilege = tag(1))
        },
        'auth@43868': {
          user: (user = "a:u:#{tag}")
        }
      }.to_json,
      message: "#{user} c #{privilege} @ #{variable}: #{success}",
      severity: info_warn(success)
    }
  end
  
  def fetch
    success = SUCCESS.sample
    user = "a:u:#{tag}"
    variable = "a:v:#{tag}"
    {
      sdata: {
        'subject@43868': { resource: variable },
        'auth@43868': { user: user }
      }.to_json,
      message: "#{user} f #{variable}: #{success}",
      severity: info_warn(success)
    }
  end
  
  def update
    success = SUCCESS.sample
    user = "a:u:#{tag}"
    variable = "a:v:#{tag}"
    {
      sdata: {
        'subject@43868': { resource: variable },
        'auth@43868': { user: user }
      }.to_json,
      message: "#{user} u #{variable}: #{success}",
      severity: success ? Syslog::LOG_NOTICE : Syslog::LOG_WARNING
    }
  end

  def timestamp
    rand(TIMESPAN)
  end
end

require 'benchmark'

puts "Generating #{COUNT} log entries..."
puts(Benchmark.measure do
  DB.copy_into(:messages, columns: Generator::COLUMNS, data: Generator.new)
end)
