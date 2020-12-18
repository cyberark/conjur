# frozen_string_literal: true

module Util
  class Multipart
    def self.parse_multipart_data(data, content_type:)
      boundary = MultipartParser::Reader::extract_boundary_value(content_type)
      reader = MultipartParser::Reader.new(boundary)

      parts={}

      reader.on_part do |part|
        pn = part.name.to_sym
        part.on_data do |partial_data|
          if parts[pn].nil?
            parts[pn] = partial_data
          else
            parts[pn] = [parts[pn]] unless parts[pn].kind_of?(Array)
            parts[pn] << partial_data
          end
        end
      end

      reader.on_error do |err|
        raise err
      end

      reader.write data
      reader.ended? or raise Exception, 'Truncated multipart message'

      parts
    end
  end
end
