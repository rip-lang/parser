require 'parslet'

require_relative './common'
require_relative './keyword'
require_relative './lambda'
require_relative './property'
require_relative './reference'

module Rip::Parser::Rules
  module Class
    include ::Parslet

    include Rip::Parser::Rules::Common
    include Rip::Parser::Rules::Keyword
    include Rip::Parser::Rules::Lambda
    include Rip::Parser::Rules::Property
    include Rip::Parser::Rules::Reference

    rule(:class_block) do
      keyword(:class) >> spaces? >> class_ancestors.maybe >> whitespaces? >> brace_open >>
        class_body.maybe.as(:body) >>
        whitespaces? >> brace_close
    end

    rule(:class_ancestors) do
      parenthesis_open >> whitespaces? >>
        csv(reference).as(:ancestors) >>
        whitespaces? >> parenthesis_close
    end

    rule(:class_body) do
      whitespaces? >> property_assignment >> spaces? >> (
        (semicolon | line_break) >> whitespaces? >> class_body
      ).repeat(0) >> whitespaces?
    end

    rule(:property_assignment) do
      class_property >> spaces? >> equals.as(:location) >> whitespaces >> property_value.as(:property_value)
    end

    rule(:class_property) do
      keyword(:class_prototype) >> spaces? >> dot >> spaces? >> property_name.as(:property_name) |
        keyword(:class_self) >> spaces? >> dot >> spaces? >> property_name.as(:property_name) |
        word.as(:property_name)
    end

    rule(:property_value) do
      import |
        class_block |
        lambda_block |
        overload_block |
        property_block |
        expression
    end

    rule(:property_block) { keyword(:swerve_rocket) >> whitespaces? >> block_body }
  end
end
