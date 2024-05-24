# frozen_string_literal: true

# Provides a user-friendly explanation for policy parsing errors

module Commands
  module Policy

    HELPFUL_EXPLANATIONS = {
      # Conjur Errors
      'Unexpected scalar' => 'Please check the syntax for defining a new node.',
      # libyaml/Psych errors
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
          "This error can occur when you have unexpected characters. putting non-alphanumeric characters in quotes might help.",
      "did not find expected alphabetic or numeric character while scanning an anchor" =>
          "This error can occur when you have unexpected characters. putting non-alphanumeric characters in quotes might help.",
      "did not find expected comment or line break while scanning a block scalar" =>
          "This error can occur when you have a problem in a block scalar.",
      "did not find expected hexdecimal number while parsing a quoted scalar" =>
          "This error can occur when you have an unexpected backslash (\\) in the indicated line",
      "did not find expected node content while parsing a block node" =>
          "This error can occur when you have an unexpected character at the beginning of the node. putting the node in quotes might help",
      "did not find expected node content while parsing a flow node" =>
          "This error can occur when you have an unexpected character at the beginning of the node. putting the node in quotes might help",
    }
    
    DEFAULT_HELP_MSG = 'This is the default error meassage. Fix me.'

    class ExplainError

      def call(original_error)
          msg = original_error.detail_message
          helptext = HELPFUL_EXPLANATIONS[msg]
          if helptext == nil
            return catch_variable_error_messages(msg)
          end
          helptext
      end

      def catch_variable_error_messages(msg)
        # Error messages that start with...
        if msg.start_with?('Invalid relative reference:')
          advice = ''
        elsif msg.start_with?('Dependency cycle encountered between')
          advice = 'Try redefining one or both.'
        elsif msg.start_with?('Please provide the record type')
          advice = ''
        elsif msg.start_with?('Duplicate anchor')
          advice = ''
        elsif msg.start_with?('Invalid IP address or CIDR range')
          advice = ''
        elsif msg.start_with?('Expecting @ for kind, got')
          advice = ''
        elsif msg.start_with?('Unexpected alias')
          advice = ''
        elsif msg.start_with?('Unrecognized data type')
          advice = ''
        elsif msg.start_with?('No such attribute')
          advice = ''
        elsif msg.start_with?('Duplicate attribute')
          advice = ''
        elsif msg.start_with?('Expecting 1 or 2 arguments, got')
          advice = ''
        
        # Error messages that start with a variable 
        # (must use end_with or include):
        
        # Attribute '#{key}' can't be a mapping
        elsif msg.end_with?()
          advice = ''
        # "Attribute '#{key}' can't be a mapping"
        elsif msg.end_with?("can't be a mapping")
          advice = ''
        # "#{record} is declared more than once"
        elsif msg.end_with?('is declared more than once')
          advice = ''
        # "#{record.class.simple_name.underscore} has a blank id"
        elsif msg.end_with?(' has a blank id')
          advice = ''
        # "YAML field #{field_name} already defined on #{name} as #{yaml_fields[field_name]}"
        # "YAML field #{field_name} already defined on #{name} as #{fields[field_name]}"
        elsif msg.include?('already defined on')
          advice = ''
        else
          advice = DEFAULT_HELP_MSG
        end
        advice
      end

  end
  end
end

