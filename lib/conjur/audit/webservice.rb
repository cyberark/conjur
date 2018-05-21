require 'json'
require 'uri'
require 'sequel'

# Simple Rack application to dump audit entries from a dataset,
# filtered by the query string.
# assumes schema:
# (
#     facility integer,
#     severity integer,
#     "timestamp" timestamp with time zone,
#     hostname text,
#     appname text,
#     procid text,
#     msgid text,
#     sdata jsonb,
#     message text
# )

# Note this is intentionally a separate rack app isolated from rest of Conjur.
# This is to allow us to be flexible and spin it off into a separate gem and
# have it run as a separate webservice, perhaps on a different host.

module Conjur
  module Audit
    class Webservice
      def initialize dataset
        @messages = dataset

        # ensure required extensions are loaded
        dataset.db.extension :pg_json
        Sequel.extension :pg_json_ops
      end

      def call env
        filtered = filter messages, URI.decode_www_form(env['QUERY_STRING'])
        if filtered.any?
          result = filtered.all.to_json
          [200, {'Content-Type' => 'text/json', 'Content-Length' => result.length}, [result]]
        else
          [404, {}, ["No records found"]]
        end
      end

      # converts [a, b, c], d into {a => {b => {c => d}}}
      def to_path_hash keys, value = nil
        return to_path_hash [*keys, value] if value
        return keys.first if keys.length == 1
        { keys.first => to_path_hash(keys.drop 1) }
      end

      # filters dataset based on given query
      # keys not in _fields_ are assumed to be in structured data
      # eg. subject@43868/role=foo looks for [subject@43868 role="foo"]
      def filter dataset, query
        fields = %w(facility severity hostname appname procid msgid)
        query.each do |key, value|
          if fields.include? key
            dataset = dataset.where key.intern => value
          else
            dataset = dataset.where Sequel[:sdata].pg_jsonb.contains to_path_hash key.split('/'), value
          end
        end
        dataset
      end

      attr_reader :messages
    end
  end
end

