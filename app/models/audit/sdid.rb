# frozen_string_literal: true

module Audit
  # RFC5424 structured data IDs for Conjur-specific audit fields.
  module SDID
    # Conjur's Private Enterprise Number
    # cf. https://pen.iana.org
    CONJUR_PEN = 43868
    def self.conjur_sdid label
      [label, CONJUR_PEN].join('@').intern
    end

    POLICY = conjur_sdid 'policy'
    AUTH = conjur_sdid 'auth'
    SUBJECT = conjur_sdid 'subject'
    ACTION = conjur_sdid 'action'
    CLIENT = conjur_sdid 'client'
  end
end
