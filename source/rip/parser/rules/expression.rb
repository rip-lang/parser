require 'parslet'

require_relative './binary_condition'
require_relative './class'
require_relative './character'
require_relative './common'
require_relative './date_time'
require_relative './import'
require_relative './invocation'
require_relative './invocation_index'
require_relative './keyword'
require_relative './lambda'
require_relative './list'
require_relative './map'
require_relative './number'
require_relative './pair'
require_relative './property'
require_relative './range'
require_relative './reference'
require_relative './string'
require_relative './unit'

module Rip::Parser::Rules
  module Expression
    include ::Parslet

    include Rip::Parser::Rules::BinaryCondition

    include Rip::Parser::Rules::Common

    include Rip::Parser::Rules::Class

    include Rip::Parser::Rules::DateTime

    include Rip::Parser::Rules::Number

    include Rip::Parser::Rules::Character
    include Rip::Parser::Rules::String

    include Rip::Parser::Rules::Lambda

    include Rip::Parser::Rules::List

    include Rip::Parser::Rules::Keyword

    include Rip::Parser::Rules::Import

    include Rip::Parser::Rules::Invocation
    include Rip::Parser::Rules::InvocationIndex

    include Rip::Parser::Rules::Map

    include Rip::Parser::Rules::Pair

    include Rip::Parser::Rules::Property

    include Rip::Parser::Rules::Range

    include Rip::Parser::Rules::Reference

    include Rip::Parser::Rules::Unit

    rule(:expression) { expression_chain }

    rule(:expression_chain) do
      (
        (
          expression_base |
            (parenthesis_open >> whitespaces? >> expression_chain >> whitespaces? >> parenthesis_close)
        ) >> expression_link.repeat
      ).as(:expression_chain)
    end

    rule(:expression_base) do
      import |

        class_block |

        lambda_block |
        overload_block |

        # enum_block |

        binary_condition |

        # switch_block |

        # exception_block_sequence |

        # query |

        date_time |
        date |
        time |

        unit |

        # version | # maybe

        number |

        character |

        string |
        regular_expression |

        # markup_fragment |

        list |

        map |

        reference
    end

    rule(:expression_link) do
      property |
        pair_value |
        range_end |
        invocation |
        invocation_index
    end
  end
end
