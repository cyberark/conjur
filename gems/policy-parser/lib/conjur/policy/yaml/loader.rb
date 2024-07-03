class Object
  # Dear Ruby, I wish instance variables order was stable, because if it was
  # then YAML would always come out the same.
  def to_yaml_properties
    instance_variables.sort
  end
end

module Conjur
  module PolicyParser
    module YAML
      class Loader
        class << self
          def load yaml, filename = nil
            dirname = if filename
              File.dirname(filename)
            else
              '.'
            end

            parser = Psych::Parser.new(handler = Handler.new)
            handler.filename = filename
            handler.parser = parser
            begin
              parser.parse(yaml)
            rescue ArgumentError
              # Loader/Handler raise these specifically, allow through
              raise
            rescue Psych::SyntaxError
              # We recognize these errors from the YAML parser interface
              raise
            rescue => e
              # We conclude that everything else must be one of the many uncategorized errors
              # from policy-parser.  Classify these as "Invalid".
              # It's generally not good practice to rescue everything, so all other known,
              # specific exceptions are rescued above and re-raised.
              handler.log { e.message }
              handler.log { e.backtrace.join("  \n") }
              raise Invalid.new(
                message: e.message || "(no message)",
                filename: filename,
                line: parser.mark.line,
                column: parser.mark.column
              )
            end
            records = handler.result || []

            parse_includes(records, dirname)

            records
          end

          def load_file filename
            load(File.read(filename), filename)
          end

          protected

          def parse_includes records, dirname
            records.each_with_index do |record, idx|
              case record
              when Array
                parse_includes(record, dirname)
              when Types::Policy
                parse_includes(record.body, dirname)
              when Types::Include
                included = load(File.read(File.expand_path(record.file, dirname)), record.file)
                records[idx..idx] = included
              end
            end
          end
        end
      end
    end
  end
end
