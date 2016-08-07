require 'parslet'

require_relative './common'
require_relative './keyword'
require_relative './list'
require_relative './reference'

module Rip::Parser::Rules
  module Lambda
    include ::Parslet

    include Rip::Parser::Rules::Common
    include Rip::Parser::Rules::Keyword
    include Rip::Parser::Rules::List
    include Rip::Parser::Rules::Reference

    rule(:lambda_block) do
      keyword(:fat_rocket) >> whitespaces? >> brace_open >> whitespaces? >>
        (whitespaces? >> overload_block >> whitespaces?).repeat(1).as(:overloads) >>
        whitespaces? >> brace_close
    end

    rule(:overload_block) do
      parameters.maybe >> whitespaces? >>
        keyword(:dash_rocket) >> whitespaces? >> block_body
    end

    rule(:parameters) do
      parenthesis_open >> whitespaces? >> parameters_list.as(:parameters) >> whitespaces? >> parenthesis_close
    end

    rule(:parameters_list) { csv(optional_parameter | required_parameter) }

    rule(:required_parameter) { word.as(:parameter) >> parameter_type_argument.maybe }
    rule(:optional_parameter) { required_parameter >> whitespaces? >> equals >> whitespaces? >> expression.as(:default) }

    rule(:parameter_type_argument) { angled_open >> spaces? >> reference.as(:type_argument) >> spaces? >> angled_close }

    rule(:block_body) do
      brace_open >> whitespaces? >>
        lines.as(:body) >>
        whitespaces? >> brace_close
    end
  end
end
