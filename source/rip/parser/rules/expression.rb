require 'parslet'

require_relative './character'
require_relative './common'
require_relative './import'
require_relative './keyword'
require_relative './list'
require_relative './number'
require_relative './reference'
require_relative './string'

module Rip::Parser::Rules
  module Expression
    include ::Parslet

    include Rip::Parser::Rules::Common

    include Rip::Parser::Rules::Number

    include Rip::Parser::Rules::Character
    include Rip::Parser::Rules::String

    include Rip::Parser::Rules::List

    include Rip::Parser::Rules::Keyword

    include Rip::Parser::Rules::Import

    include Rip::Parser::Rules::Reference

    rule(:expression) do
      expression_base |
        parenthesis_open >> whitespaces? >> expression >> whitespaces? >> parenthesis_close
    end

    rule(:expression_base) do
      import |

        # class_block |

        # lambda_block |
        # overload_block |

        # condition_block_sequence |

        # switch_block |

        # exception_block_sequence |

        # date_time |
        # date |
        # time |

        # unit | # maybe

        # version | # maybe

        number |

        character |

        string |
        regular_expression |

        list |

        # map |

        reference
    end
  end
end
