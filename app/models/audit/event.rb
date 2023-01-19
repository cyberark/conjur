module Audit
  module Event
    # "progname" is required by ruby's Syslog::Logger interface. See:
    # https://ruby-doc.org/stdlib-2.6.3/libdoc/syslog/rdoc/Syslog/Logger.html#method-i-add
    def self.progname
      "conjur"
    end
  end
end
