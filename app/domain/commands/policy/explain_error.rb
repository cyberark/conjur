# frozen_string_literal: true

# Provides a user-friendly explanation for policy parsing errors

module Commands
  module Policy

    # TODO: group these by exception (to make maintenance easier)
    HELPFUL_EXPLANATIONS = {
      ## Conjur::PolicyParser::Invalid Error Messages
      # From conjur/gems/policy-parser/lib/conjur/policy/resolver.rb
      "account is required" =>
        "",
      "ownerid is required" =>
        "",
      "ownerid must be fully qualified account, kind and identifier" =>
        "",
      # From conjur/gems/policy-parser/lib/conjur/policy/types/base.rb
      "Attribute :kind must be defined, explicitly or inferred from :type" =>
        "",
      # From conjur/gems/policy-parser/lib/conjur/policy/yaml/handler.rb
      "Unexpected start of document" =>
        "",
      "Unexpected scalar" =>
        "Please check the syntax for defining a new node.",
      "Unexpected mapping" =>
        "",
      "Unexpected sequence" =>
        "",
      "Unexpected end of document" =>
        "",
      "Unexpected end of sequence" =>
        "",
      "Unexpected end of mapping" =>
        "",
      "Already got sequence result" =>
        "",
      "Multiple YAML documents encountered. Only a single document is permitted per policy." =>
        "",
      "No type given or inferred for sequence entry" =>
        "",

      # Psych::SyntaxError (libyaml) Error Messages
      "block sequence entries are not allowed in this context" =>
        "This error can occur when you have an unnecessary '-' at the beginning of a line",
      "could not find expected ':' while scanning a simple key" =>
        "This error can occur when you have a missing ':' or missing space after ':'",
      "did not find expected '-' indicator while parsing a block collection" =>
        "This error can occur when you have an indentation problem",
      "did not find expected ',' or ']' while parsing a flow sequence" =>
        "This error can occur when you don't end a list properly, or have a problem element in the list",
      "did not find expected ',' or '}' while parsing a flow mapping" =>
        "This error can occur when you don't end a mapping properly, or have a problem element in the mapping",
      "did not find expected '!' while scanning a tag" =>
        "This error can occur when you're missing the '!' at the beginning of a tag (the allowable tags are: !delete, !deny, !grant, !group, !host, !host-factory, !layer, !permit, !policy, !revoke, !user, !variable, !webservice)",
      "did not find expected <document start>" =>
        "This error can occur when you have unnecessary white space on your YAML header",
      "did not find expected alphabetic or numeric character while scanning an alias" =>
        "This error can occur when you have unexpected characters. Putting terms containing non-alphanumeric characters in quotes might help.",
      "did not find expected alphabetic or numeric character while scanning an anchor" =>
        "This error can occur when you have unexpected characters. Putting terms containing non-alphanumeric characters in quotes might help.",
      "did not find expected comment or line break while scanning a block scalar" =>
        "This error can occur when you have a problem in a block scalar.",
      "did not find expected hexdecimal number while parsing a quoted scalar" =>
        "This error can occur when you have an unexpected backslash (\\) in the indicated line",
      "did not find expected node content while parsing a block node" =>
        "This error can occur when you have an unexpected character at the beginning of the node. Putting the node in quotes might help",
      "did not find expected node content while parsing a flow node" =>
        "This error can occur when you have an unexpected character at the beginning of the node. putting the node in quotes might help",
      "did not find expected tag URI while parsing a tag" =>
        "",
      "did not find expected whitespace or line break while scanning a tag" =>
        "Only one node can be defined per line.",
      "did not find the expected '>' while scanning a tag" =>
        "",
      "did not find URI escaped octet while parsing a tag" =>
        "",
      "found a tab character that violates indentation while scanning a plain scalar" =>
        "You must use spaces for indentation, not tabs.",
      "found a tab character where an indentation space is expected while scanning a block scalar" =>
        "",
      "found an incorrect leading UTF-8 octet while parsing a tag" =>
        "",
      "found an incorrect trailing UTF-8 octet while parsing a tag" =>
        "",
      "found an indentation indicator equal to 0 while scanning a block scalar" =>
        "",
      "found character that cannot start any token while scanning for the next token" =>
        "",
      "found incompatible YAML document" =>
        "",
      "found invalid Unicode character escape code while parsing a quoted scalar" =>
        "",
      "found undefined tag handle while parsing a node" =>
        "",
      "found unexpected ':' while scanning a plain scalar" =>
        "",
      "found unexpected document indicator while scanning a quoted scalar" =>
        "",
      "found unexpected end of stream while scanning a quoted scalar" =>
        "",
      "found unknown escape character while parsing a quoted scalar" =>
        "",
      "mapping keys are not allowed in this context" =>
        "",
      "mapping values are not allowed in this context" =>
        "",
      "Maximum nesting level reached, set with yaml_set_max_nest_level()) while parsing" =>
        "",

    }.freeze

    DEFAULT_HELP_MSG = ''

    class ExplainError

      def call(parse_error)
        msg = parse_error.detail_message
        advice = HELPFUL_EXPLANATIONS[msg]
        if (advice == nil) || (advice == '')
          advice = catch_variable_error_messages(msg)
        end
        advice
      end

      def catch_variable_error_messages(msg)
        ##### Conjur::PolicyParser::Invalid Errors #####
        # From conjur/gems/policy-parser/lib/conjur/policy/yaml/handler.rb
        if msg.start_with?("Unexpected alias")
          # Unexpected alias #{anchor}
          advice = ''
        elsif msg.start_with?("Unrecognized data type")
          # Unrecognized data type '#{tag}'
          advice = 'The tag must be one of the following: !delete, !deny, !grant, !group, !host, !host-factory, !layer, !permit, !policy, !revoke, !user, !variable, !webservice'
        elsif msg.start_with?("No such attribute")
          # No such attribute '#{key}' on type #{@record.class.short_name}
          advice = ''
        elsif msg.start_with?("Duplicate attribute: ")
          # Duplicate attribute: #{value}
          advice = ''
        elsif msg.start_with?("Attribute ") && msg.end_with?(" can't be a mapping")
          # Attribute '#{key}' can't be a mapping
          advice = ''
        elsif msg.start_with?("Expecting 1 or 2 arguments, got")
          # Expecting 1 or 2 arguments, got #{args.length}
          advice = ''
        elsif msg.start_with?("Duplicate anchor ")
          # Duplicate anchor #{key}
          advice = ''
          # From conjur/gems/policy-parser/lib/conjur/policy/types/records.rb
        elsif msg.start_with?("Expecting @ for kind, got ")
          # Expecting @ for kind, got #{kind}
          advice = ''
          # From conjur/gems/policy-parser/lib/conjur/policy/types/base.rb
        elsif msg.start_with?("Expected a") && msg.include?('for field')
          # Expected a #{type_name} for field '#{attr_name}', got #{name}
          advice = ''
        elsif msg.start_with?('Invalid IP address or CIDR range') && msg.include?('Value has bits set to right of mask. Did you mean')
          # Invalid IP address or CIDR range '#{value}': Value has bits set to right of mask. Did you mean '#{cidr}'?
          advice = ''
        elsif msg.start_with?('Invalid IP address or CIDR range')
          # Invalid IP address or CIDR range '#{value}'
          advice = "Make sure your address or range is in the correct format (e.g. 192.168.1.0 or 192.168.1.0/16)"
        elsif msg.start_with?('YAML field') && msg.include?('already defined on')
          # YAML field #{field_name} already defined on #{name} as #{yaml_fields[field_name]}
          # YAML field #{field_name} already defined on #{name} as #{fields[field_name]}
          advice = ''
          # From conjur/gems/policy-parser/lib/conjur/policy/resolver.rb
        elsif msg.end_with?('has a blank id')
          # #{record.class.simple_name.underscore} has a blank id
          advice = "Each resource must be identified using the 'id' field"

        elsif msg.start_with?('Invalid relative reference')
          # Invalid relative reference: #{id}
          advice = ''
        elsif msg.start_with?('Dependency cycle encountered between')
          # Dependency cycle encountered between #{a} and #{b}
          advice = "Try redefining one or both."
        elsif msg.end_with?('is declared more than once')
          # #{record} is declared more than once
          advice = ''
        else
          advice = ''
        end


        advice
      end
    end
  end
end
