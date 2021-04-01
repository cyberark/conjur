require 'openssl'

# An OpenSSL::X509::Attribute representing an extension request is a Set
# containing an array of one Sequence object, which itself holds an array of
# extension objects. These extension objects may be represented in different
# ways, and this object encapsulates those differences (see note on
# `all_extensions` method below.)
#
# Indeed, this object abstracts away all of the above implementation detail,
# allowing us to:
#
# 1. Easily create the "attribute value" from an array of extensions
# 2. Look up individual extensions by name
#
module Util
  module OpenSsl
    module X509
      class ExtensionRequestAttributeValue

        def self.from_extensions(extensions)
          new(OpenSSL::ASN1::Set([ OpenSSL::ASN1::Sequence(extensions) ]))
        end

        def initialize(asn1_set)
          @asn1_set = asn1_set
        end

        def value
          @asn1_set
        end

        def extension(ext_name)
          all_extensions.find { |x| x.oid == ext_name }
        end

        private

        # When the object is created from an actual parsed certificate, as opposed to
        # an array of Extension objects, each extension is represented by an
        # ASN1::Sequence whose value is an array of ASN1::ASN1Data objects.
        #
        # These Sequences may be passed to the Extension constructor to create a
        # proper Extension object. Otoh, passing an existing Extension object is a
        # no-op, so this works in both cases.
        #
        def all_extensions
          @all_extensions ||=
            sequence.value.map { |x| OpenSSL::X509::Extension.new(x) }
        end

        def sequence
          @asn1_set.value.first
        end
      end
    end
  end
end
