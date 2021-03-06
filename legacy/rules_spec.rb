require 'spec_helper'

describe Rip::Parser::Rules, :blur do
  let(:rules) { Rip::Parser::Rules.new }

  context 'some basics' do
    it 'parses an empty module' do
      expect('').to parse_raw_as(:module => [])
    end

    it 'parses an empty string module' do
      expect('       ').to parse_raw_as(:module => '       ')
    end

    it 'ignores comments as whitespace' do
      expect('# this is a comment').to parse_raw_as(:module => '# this is a comment')
    end

    it 'recognizes various whitespace sequences' do
      {
        [' ', "\t", "\r", "\n", "\r\n"] => :whitespace,
        [' ', "\t\t"]                   => :whitespaces,
        ['', "\n", "\t\r"]              => :whitespaces?,
        [' ', "\t"]                     => :space,
        [' ', "\t\t", "  \t  \t  "]     => :spaces,
        ['', ' ', "  \t  \t  "]         => :spaces?,
        ["\n", "\r", "\r\n"]            => :line_break,
        ["\r\n\r\n", "\n\n"]            => :line_breaks,
        ['', "\r\n\r\n", "\n\n"]        => :line_breaks?
      }.each do |whitespaces, method|
        space_parser = Rip::Parser::Rules.new.send(method)
        whitespaces.each do |space|
          expect(space_parser).to parse(space).as(space)
        end
      end
    end

    context 'comma-separation' do
      let(:csv_parser) do
        parser = Rip::Parser::Rules.new
        parser.send(:csv, parser.send(:str, 'x').as(:x)).as(:csv)
      end
      let(:expected_x) { { :x => 'x' } }

      it 'recognizes comma-separated atoms' do
        expect(csv_parser).to parse('').as(:csv => [])
        expect(csv_parser).to parse('x').as(:csv => [expected_x])
        expect(csv_parser).to parse('x,x,x').as(:csv => [expected_x, expected_x, expected_x])
        expect(csv_parser).to_not parse('xx')
        expect(csv_parser).to_not parse('x,xx')
      end
    end
  end

  recognizes_as_expected 'several statements together' do
    let(:rip) do
      strip_heredoc(<<-RIP)
        if (true) {
          lambda = -> {
            # comment
          }
          lambda()
        } else {
          1 + 2
        }
      RIP
    end
    let(:expected_raw) do
      {
        :module => [
          {
            :if_block => {
              :if => 'if',
              :argument => { :reference => 'true' },
              :location_body => '{',
              :body => [
                {
                  :atom => [
                    { :reference => 'lambda' },
                    {
                      :assignment => {
                        :location => '=',
                        :rhs => {
                          :dash_rocket => '->',
                          :location_body => '{',
                          :body => []
                        }
                      }
                    }
                  ]
                },
                {
                  :atom => [
                    { :reference => 'lambda' },
                    { :regular_invocation => { :location => '(', :arguments => [] } }
                  ]
                }
              ]
            },
            :else_block => {
              :else => 'else',
              :location_body => '{',
              :body => [
                {
                  :atom => [
                    { :integer => '1' },
                    {
                      :operator_invocation => {
                        :operator => '+',
                        :argument => { :integer => '2' }
                      }
                    }
                  ]
                }
              ]
            }
          }
        ]
      }
    end
  end

  describe '#expression' do
    context 'block' do
      recognizes_as_expected 'empty block' do
        let(:rip) { 'try {}' }
        let(:expected_raw) do
          {
            :module => [
              {
                :try_block => {
                  :try => 'try',
                  :location_body => '{',
                  :body => []
                },
                :catch_blocks => []
              }
            ]
          }
        end
      end

      recognizes_as_expected 'block with argument' do
        let(:rip) { 'if (:name) {} else {}' }
        let(:expected_raw) do
          {
            :module => [
              {
                :if_block => {
                  :if => 'if',
                  :argument => {
                    :location => ':',
                    :string => rip_string_raw('name')
                  },
                  :location_body => '{',
                  :body => []
                },
                :else_block => {
                  :else => 'else',
                  :location_body => '{',
                  :body => []
                }
              }
            ]
          }
        end
      end

      recognizes_as_expected 'block with multiple arguments' do
        let(:rip) { 'type (one, two) {}' }
        let(:expected_raw) do
          {
            :module => [
              {
                :type => 'type',
                :arguments => [
                  { :reference => 'one' },
                  { :reference => 'two' }
                ],
                :location_body => '{',
                :body => []
              }
            ]
          }
        end
      end

      recognizes_as_expected 'type with no super_types' do
        let(:rip) do
          <<-RIP
            type {
              # comment
            }
          RIP
        end
        let(:expected_raw) do
          {
            :module => [
              {
                :type => 'type',
                :location_body => '{',
                :body => []
              }
            ]
          }
        end
      end

      recognizes_as_expected 'overload with no parameters' do
        let(:rip) { '-> {}' }
        let(:expected_raw) do
          {
            :module => [
              {
                :dash_rocket => '->',
                :location_body => '{',
                :body => []
              }
            ]
          }
        end
      end

      recognizes_as_expected 'lambda with no parameters' do
        let(:rip) { '=> { -> {} }' }
        let(:expected_raw) do
          {
            :module => [
              {
                :fat_rocket => '=>',
                :location_body => '{',
                :overload_blocks => [
                  {
                    :dash_rocket => '->',
                    :location_body => '{',
                    :body => []
                  }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'overload with multiple required parameters' do
        let(:rip) { '-> (one, two) {}' }
        let(:expected_raw) do
          {
            :module => [
              {
                :dash_rocket => '->',
                :parameters => [
                  { :parameter => 'one' },
                  { :parameter => 'two' }
                ],
                :location_body => '{',
                :body => []
              }
            ]
          }
        end
      end

      recognizes_as_expected 'overload with multiple required parameters with type restrictions' do
        let(:rip) { '-> (one, two<CustomType>) {}' }
        let(:expected_raw) do
          {
            :module => [
              {
                :dash_rocket => '->',
                :parameters => [
                  { :parameter => 'one' },
                  {
                    :parameter => 'two',
                    :type_argument => {
                      :reference => 'CustomType'
                    }
                  }
                ],
                :location_body => '{',
                :body => []
              }
            ]
          }
        end
      end

      recognizes_as_expected 'overload with multiple optional parameters' do
        let(:rip) { '-> (one = 1, two = 2) {}' }
        let(:expected_raw) do
          {
            :module => [
              {
                :dash_rocket => '->',
                :parameters => [
                  {
                    :parameter => 'one',
                    :default_expression => { :integer => '1' }
                  },
                  {
                    :parameter => 'two',
                    :default_expression => { :integer => '2' }
                  }
                ],
                :location_body => '{',
                :body => []
              }
            ]
          }
        end
      end

      recognizes_as_expected 'overload with multiple optional parameters with type restrictions' do
        let(:rip) { '-> (one<System.Integer> = 1, two = 2) {}' }
      end

      recognizes_as_expected 'overload with required parameter and optional parameter' do
        let(:rip) { '-> (platform, name = :rip) {}' }
        let(:expected_raw) do
          {
            :module => [
              {
                :dash_rocket => '->',
                :parameters => [
                  { :parameter => 'platform' },
                  {
                    :parameter => 'name',
                    :default_expression => {
                      :location => ':',
                      :string => rip_string_raw('rip')
                    }
                  }
                ],
                :location_body => '{',
                :body => []
              }
            ]
          }
        end
      end

      recognizes_as_expected 'overload with multiple required parameter and multiple optional parameter' do
        let(:rip) { '-> (abc, xyz, one = 1, two = 2) {}' }
        let(:expected_raw) do
          {
            :module => [
              {
                :dash_rocket => '->',
                :parameters => [
                  { :parameter => 'abc' },
                  { :parameter => 'xyz' },
                  {
                    :parameter => 'one',
                    :default_expression => { :integer => '1' }
                  },
                  {
                    :parameter => 'two',
                    :default_expression => { :integer => '2' }
                  }
                ],
                :location_body => '{',
                :body => []
              }
            ]
          }
        end
      end

      recognizes_as_expected 'blocks with block arguments' do
        let(:rip) { 'type (type () {}) {}' }
        let(:expected_raw) do
          {
            :module => [
              {
                :type => 'type',
                :arguments => [
                  {
                    :type => 'type',
                    :arguments => [],
                    :location_body => '{',
                    :body => []
                  }
                ],
                :location_body => '{',
                :body => []
              }
            ]
          }
        end
      end

      recognizes_as_expected 'switch' do
        let(:rip) { 'switch (foo) { case (true) { 42 } else { 0 } }' }
        let(:expected_raw) do
          {
            :module => [
              {
                :switch => 'switch',
                :argument => { :reference => 'foo' },
                :case_blocks => [
                  {
                    :case => 'case',
                    :arguments => [
                      { :reference => 'true' }
                    ],
                    :location_body => '{',
                    :body => [
                      { :integer => '42' }
                    ]
                  }
                ],
                :else_block => {
                  :else => 'else',
                  :location_body => '{',
                  :body => [
                    { :integer => '0' }
                  ]
                }
              }
            ]
          }
        end
      end

      recognizes_as_expected 'switch without argument' do
        let(:rip) { 'switch { case (true) { 42 } else { 0 } }' }
        let(:expected_raw) do
          {
            :module => [
              {
                :switch => 'switch',
                :case_blocks => [
                  {
                    :case => 'case',
                    :arguments => [
                      { :reference => 'true' }
                    ],
                    :location_body => '{',
                    :body => [
                      { :integer => '42' }
                    ]
                  }
                ],
                :else_block => {
                  :else => 'else',
                  :location_body => '{',
                  :body => [
                    { :integer => '0' }
                  ]
                }
              }
            ]
          }
        end
      end

      recognizes_as_expected 'try-catch' do
        let(:rip) { 'try {} catch (Exception: e) {}' }
        let(:expected_raw) do
          {
            :module => [
              {
                :try_block => {
                  :try => 'try',
                  :location_body => '{',
                  :body => []
                },
                :catch_blocks => [
                  {
                    :catch => 'catch',
                    :argument => {
                      :atom => [
                        { :reference => 'Exception' },
                        {
                          :key_value_pair => {
                            :location => ':',
                            :value => { :reference => 'e' }
                          }
                        }
                      ]
                    },
                    :location_body => '{',
                    :body => []
                  }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'try-finally' do
        let(:rip) { 'try {} finally {}' }
      end

      recognizes_as_expected 'try-catch-finally' do
        let(:rip) { 'try {} catch (Exception: e) {} finally {}' }
      end
    end

    context 'block body' do
      recognizes_as_expected 'comments inside block body' do
        let(:rip) do
          <<-RIP
          -> (x) {
            # comment
          }
          RIP
        end
        let(:expected_raw) do
          {
            :module => [
              {
                :dash_rocket => '->',
                :parameters => [
                  { :parameter => 'x' }
                ],
                :location_body => '{',
                :body => []
              }
            ]
          }
        end
      end

      recognizes_as_expected 'references inside block body' do
        let(:rip) { '-> (x) { name }' }
        let(:expected_raw) do
          {
            :module => [
              {
                :dash_rocket => '->',
                :parameters => [
                  { :parameter => 'x' }
                ],
                :location_body => '{',
                :body => [
                  { :reference => 'name' }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'assignments inside block body' do
        let(:rip) { '-> (foo) { x = :y }' }
        let(:expected_raw) do
          {
            :module => [
              {
                :dash_rocket => '->',
                :parameters => [
                  { :parameter => 'foo' }
                ],
                :location_body => '{',
                :body => [
                  {
                    :atom => [
                      { :reference => 'x' },
                      {
                        :assignment => {
                          :location => '=',
                          :rhs => {
                            :location => ':',
                            :string => rip_string_raw('y')
                          }
                        }
                      }
                    ]
                  }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'invocations inside block body' do
        let(:rip) { '-> (run!) { run!() }' }
        let(:expected_raw) do
          {
            :module => [
              {
                :dash_rocket => '->',
                :parameters => [
                  { :parameter => 'run!' }
                ],
                :location_body => '{',
                :body => [
                  {
                    :atom => [
                      { :reference => 'run!' },
                      { :regular_invocation => { :location => '(', :arguments => [] } }
                    ]
                  }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'operator invocations inside block body' do
        let(:rip) { '-> (steam) { steam will :rise }' }
        let(:expected_raw) do
          {
            :module => [
              {
                :dash_rocket => '->',
                :parameters => [
                  { :parameter => 'steam' }
                ],
                :location_body => '{',
                :body => [
                  {
                    :atom => [
                      { :reference => 'steam' },
                      {
                        :operator_invocation => {
                          :operator => 'will',
                          :argument => {
                            :location => ':',
                            :string => rip_string_raw('rise')
                          }
                        }
                      }
                    ]
                  }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'literals inside block body' do
        let(:rip) { '-> (n) { `3 }' }
        let(:expected_raw) do
          {
            :module => [
              {
                :dash_rocket => '->',
                :parameters => [
                  { :parameter => 'n' }
                ],
                :location_body => '{',
                :body => [
                  {
                    :location => '`',
                    :character => '3'
                  }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'blocks inside block body' do
        let(:rip) { '-> (foo) { if (false) { 42 } else { -42 } }' }
        let(:expected_raw) do
          {
            :module => [
              {
                :dash_rocket => '->',
                :parameters => [
                  { :parameter => 'foo' }
                ],
                :location_body => '{',
                :body => [
                  {
                    :if_block => {
                      :if => 'if',
                      :argument => { :reference => 'false' },
                      :location_body => '{',
                      :body => [
                        { :integer => '42' }
                      ]
                    },
                    :else_block => {
                      :else => 'else',
                      :location_body => '{',
                      :body => [
                        { :sign => '-', :integer => '42' }
                      ]
                    }
                  }
                ]
              }
            ]
          }
        end
      end
    end

    recognizes_as_expected 'keyword' do
      let(:rip) { 'return;' }
      let(:expected_raw) do
        {
          :module => [
            { :return => 'return' }
          ]
        }
      end
    end

    recognizes_as_expected 'keyword followed by phrase' do
      let(:rip) { 'exit 0' }
      let(:expected_raw) do
        {
          :module => [
            {
              :exit => 'exit',
              :payload => { :integer => '0' }
            }
          ]
        }
      end
    end

    recognizes_as_expected 'keyword followed by parenthesis around phrase' do
      let(:rip) { 'throw (e)' }
      let(:expected_raw) do
        {
          :module => [
            {
              :throw => 'throw',
              :payload => { :reference => 'e' }
            }
          ]
        }
      end
    end

    context 'multiple expressions' do
      recognizes_as_expected 'terminates expressions properly' do
        let(:rip) do
          <<-RIP
            one
            two
            three
          RIP
        end
        let(:expected_raw) do
          {
            :module => [
              { :reference => 'one' },
              { :reference => 'two' },
              { :reference => 'three' }
            ]
          }
        end
      end

      recognizes_as_expected 'allows expressions to take more than one line' do
        let(:rip) do
          <<-RIP
            1 +
              2 -
              3
          RIP
        end
        let(:expected_raw) do
          {
            :module => [
              {
                :atom => [
                  { :integer => '1' },
                  {
                    :operator_invocation => {
                      :operator => '+',
                      :argument => { :integer => '2' }
                    }
                  },
                  {
                    :operator_invocation => {
                      :operator => '-',
                      :argument => { :integer => '3' }
                    }
                  }
                ]
              }
            ]
          }
        end
      end
    end

    context 'invoking lambdas' do
      recognizes_as_expected 'overload literal invocation' do
        let(:rip) { '-> () {}()' }
        let(:expected_raw) do
          {
            :module => [
              {
                :atom => [
                  {
                    :dash_rocket => '->',
                    :parameters => [],
                    :location_body => '{',
                    :body => []
                  },
                  :regular_invocation => { :location => '(', :arguments => [] }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'lambda reference invocation' do
        let(:rip) { 'full_name()' }
        let(:expected_raw) do
          {
            :module => [
              {
                :atom => [
                  { :reference => 'full_name' },
                  { :regular_invocation => { :location => '(', :arguments => [] } }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'lambda reference invocation arguments' do
        let(:rip) { 'full_name(:Thomas, :Ingram)' }
        let(:expected_raw) do
          {
            :module => [
              {
                :atom => [
                  { :reference => 'full_name' },
                  {
                    :regular_invocation => {
                      :location => '(',
                      :arguments => [
                        { :location => ':', :string => rip_string_raw('Thomas') },
                        { :location => ':', :string => rip_string_raw('Ingram') }
                      ]
                    }
                  }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'index invocation' do
        let(:rip) { 'list[0]' }
        let(:expected_raw) do
          {
            :module => [
              {
                :atom => [
                  { :reference => 'list' },
                  {
                    :index_invocation => {
                      :open => '[',
                      :arguments => [
                        { :integer => '0' }
                      ],
                      :close => ']'
                    }
                  }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'operator invocation' do
        let(:rip) { '2 + 2' }
        let(:expected_raw) do
          {
            :module => [
              {
                :atom => [
                  { :integer => '2' },
                  {
                    :operator_invocation => {
                      :operator => '+',
                      :argument => { :integer => '2' }
                    }
                  }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'reference assignment' do
        let(:rip) { 'favorite_language = :rip' }
        let(:expected_raw) do
          {
            :module => [
              {
                :atom => [
                  { :reference => 'favorite_language' },
                  {
                    :assignment => {
                      :location => '=',
                      :rhs => { :location => ':', :string => rip_string_raw('rip') }
                    }
                  }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'property assignment' do
        let(:rip) { 'favorite.language = :rip.lang' }
        let(:expected_raw) do
          {
            :module => [
              {
                :atom => [
                  {
                    :atom => [
                      { :reference => 'favorite' },
                      {
                        :location => '.',
                        :property_name => 'language'
                      }
                    ]
                  },
                  {
                    :assignment => {
                      :location => '=',
                      :rhs => {
                        :atom => [
                          { :location => ':', :string => rip_string_raw('rip') },
                          {
                            :location => '.',
                            :property_name => 'lang'
                          }
                        ]
                      }
                    }
                  }
                ]
              }
            ]
          }
        end
      end
    end

    context 'nested parenthesis' do
      recognizes_as_expected 'anything surrounded by parenthesis' do
        let(:rip) { '(0)' }
        let(:expected_raw) do
          {
            :module => [
              { :integer => '0' }
            ]
          }
        end
      end

      recognizes_as_expected 'anything surrounded by parenthesis with crazy nesting' do
        let(:rip) { '((((((l((1 + (((2 - 3)))))))))))' }
        let(:expected_raw) do
          {
            :module => [
              {
                :atom => [
                  { :reference => 'l' },
                  {
                    :regular_invocation => {
                      :location => '(',
                      :arguments => [
                        {
                          :atom => [
                            { :integer => '1' },
                            {
                              :operator_invocation => {
                                :operator => '+',
                                :argument => {
                                  :atom => [
                                    { :integer => '2' },
                                    {
                                      :operator_invocation => {
                                        :operator => '-',
                                        :argument => { :integer => '3' }
                                      }
                                    }
                                  ]
                                }
                              }
                            }
                          ]
                        }
                      ]
                    }
                  }
                ]
              }
            ]
          }
        end
      end
    end

    context 'property chaining' do
      recognizes_as_expected 'chaining with properies and invocations' do
        let(:rip) { '0.one().two.three()' }
        let(:expected_raw) do
          {
            :module => [
              {
                :atom => [
                  { :integer => '0' },
                  {
                    :location => '.',
                    :property_name => 'one'
                  },
                  { :regular_invocation => { :location => '(', :arguments => [] } },
                  {
                    :location => '.',
                    :property_name => 'two'
                  },
                  {
                    :location => '.',
                    :property_name => 'three'
                  },
                  { :regular_invocation => { :location => '(', :arguments=> [] } }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'chaining off opererators' do
        let(:rip) { '(1 - 2).zero?()' }
        let(:expected_raw) do
          {
            :module => [
              {
                :atom => [
                  {
                    :atom => [
                      { :integer => '1' },
                      {
                        :operator_invocation => {
                          :operator => '-',
                          :argument => { :integer => '2' }
                        }
                      }
                    ]
                  },
                  {
                    :location => '.',
                    :property_name => 'zero?'
                  },
                  { :regular_invocation => { :location => '(', :arguments => [] } }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'chaining several opererators' do
        let(:rip) { '1 + 2 + 3 + 4' }
        let(:expected_raw) do
          {
            :module => [
              {
                :atom => [
                  { :integer => '1' },
                  {
                    :operator_invocation => {
                      :operator => '+',
                      :argument => { :integer => '2' }
                    }
                  },
                  {
                    :operator_invocation => {
                      :operator => '+',
                      :argument => { :integer => '3' }
                    }
                  },
                  {
                    :operator_invocation => {
                      :operator => '+',
                      :argument => { :integer => '4' }
                    }
                  }
                ]
              }
            ]
          }
        end
      end
    end

    context 'atomic literals' do
      describe 'numbers' do
        recognizes_as_expected 'integer' do
          let(:rip) { '42' }
          let(:expected_raw) do
            {
              :module => [
                { :integer => '42' }
              ]
            }
          end
        end

        recognizes_as_expected 'decimal' do
          let(:rip) { '4.2' }
          let(:expected_raw) do
            {
              :module => [
                { :decimal => '4.2' }
              ]
            }
          end
        end

        recognizes_as_expected 'negative number' do
          let(:rip) { '-3' }
          let(:expected_raw) do
            {
              :module => [
                { :sign => '-', :integer => '3' }
              ]
            }
          end
        end

        recognizes_as_expected 'large number' do
          let(:rip) { '123_456_789' }
          let(:expected_raw) do
            {
              :module => [
                { :integer => '123_456_789' }
              ]
            }
          end
        end
      end

      recognizes_as_expected 'regular character' do
        let(:rip) { '`9' }
        let(:expected_raw) do
          {
            :module => [
              {
                :location => '`',
                :character => '9'
              }
            ]
          }
        end
      end

      recognizes_as_expected 'escaped character' do
        let(:rip) { '`\n' }
        let(:expected_raw) do
          {
            :module => [
              {
                :location => '`',
                :character => { :location => '\\', :escaped_token => 'n' }
              }
            ]
          }
        end
      end

      recognizes_as_expected 'symbol string' do
        let(:rip) { ':0' }
        let(:expected_raw) do
          {
            :module => [
              {
                :location => ':',
                :string => [
                  { :character => '0' }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'symbol string with escape' do
        let(:rip) { ':on\e' }
        let(:expected_raw) do
          {
            :module => [
              {
                :location => ':',
                :string => [
                  { :character => 'o' },
                  { :character => 'n' },
                  { :character => '\\' },
                  { :character => 'e' }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'single-quoted string (empty)' do
        let(:rip) { "''" }
        let(:expected_raw) do
          {
            :module => [
              {
                :location => '\'',
                :string => []
              }
            ]
          }
        end
      end

      recognizes_as_expected 'single-quoted string' do
        let(:rip) { '\'two\'' }
        let(:expected_raw) do
          {
            :module => [
              {
                :location => '\'',
                :string => [
                  { :character => 't' },
                  { :character => 'w' },
                  { :character => 'o' }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'double-quoted string (empty)' do
        let(:rip) { '""' }
        let(:expected_raw) do
          {
            :module => [
              {
                :location => '"',
                :string => []
              }
            ]
          }
        end
      end

      recognizes_as_expected 'double-quoted string' do
        let(:rip) { '"a\nb"' }
        let(:expected_raw) do
          {
            :module => [
              {
                :location => '"',
                :string => [
                  { :character => 'a' },
                  { :character => { :location => '\\', :escaped_token => 'n' } },
                  { :character => 'b' }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'double-quoted string with interpolation' do
        let(:rip) { '"ab#{cd}ef"' }
        let(:expected_raw) do
          {
            :module => [
              {
                :location => '"',
                :string => rip_string_raw('ab') + [{ :start => '#{', :interpolation => [
                  { :reference => 'cd' }
                ], :end => '}' }] + rip_string_raw('ef')
              }
            ]
          }
        end
      end

      recognizes_as_expected 'empty heredoc' do
        let(:rip) { "<<HERE_DOC\nHERE_DOC" }
        let(:expected_raw) do
          {
            :module => [
              {
                :location => '<<',
                :string => rip_string_raw('')
              }
            ]
          }
        end
      end

      recognizes_as_expected 'heredoc with just blank lines' do
        let(:rip) { "<<HERE_DOC\r\n\r\n\r\nHERE_DOC\r\n" }
        let(:expected_raw) do
          {
            :module => [
              {
                :location => '<<',
                :string => [
                  { :line_break => "\r\n" },
                  { :line_break => "\r\n" }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'heredoc with just indented lines' do
        let(:rip) { "\t<<HERE_DOC\n\t\n\t\n\tHERE_DOC\n" }
        let(:expected_raw) do
          {
            :module => [
              {
                :location => '<<',
                :string => rip_string_raw("\t") + [ { :line_break => "\n" } ] + rip_string_raw("\t") + [ { :line_break => "\n" } ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'heredoc containing label' do
        let(:rip) do
          strip_heredoc(<<-RIP)
            <<HERE_DOC
            i'm a HERE_DOC
            HERE_DOC are multi-line strings
            HERE_DOC
          RIP
        end
      end

      recognizes_as_expected 'heredoc with interpolation' do
        let(:rip) do
          strip_heredoc(<<-RIP)
            <<HERE_DOC
            here docs are good for
            strings that \#{need} multiple lines
            advantageous, eh?
            HERE_DOC
          RIP
        end
        let(:expected_raw) do
          {
            :module => [
              {
                :location => '<<',
                :string => rip_string_raw('here docs are good for') + [ { :line_break => "\n" } ] +
                  rip_string_raw('strings that ') + [{ :start => '#{', :interpolation => [
                    { :reference => 'need' }
                  ], :end => '}' }] +
                  rip_string_raw(' multiple lines') + [ { :line_break => "\n" } ] +
                  rip_string_raw('advantageous, eh?') + [ { :line_break => "\n" } ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'regular expression (empty)' do
        let(:rip) { '//' }
        let(:expected_raw) do
          {
            :module => [
              {
                :location => '/',
                :regex => []
              }
            ]
          }
        end
      end

      recognizes_as_expected 'regular expression' do
        let(:rip) { '/hello/' }
        let(:expected_raw) do
          {
            :module => [
              {
                :location => '/',
                :regex => [
                  { :character => 'h' },
                  { :character => 'e' },
                  { :character => 'l' },
                  { :character => 'l' },
                  { :character => 'o' }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'regular expression with interpolation' do
        let(:rip) { '/he#{ll}o/' }
        let(:expected_raw) do
          {
            :module => [
              {
                :location => '/',
                :regex => [
                  { :character => 'h' },
                  { :character => 'e' },
                  {
                    :start => '#{',
                    :interpolation_regex => [
                      { :reference => 'll' }
                    ],
                    :end => '}'
                  },
                  { :character => 'o' }
                ]
              }
            ]
          }
        end
      end
    end

    context 'date and time literals' do
      recognizes_as_expected 'date' do
        let(:rip) { '2012-02-12' }
        let(:expected_raw) do
          {
            :module => [
              {
                :year => '2012',
                :month => '02',
                :day => '12'
              }
            ]
          }
        end
      end

      recognizes_as_expected 'time' do
        let(:rip) { '05:24:00' }
        let(:expected_raw) do
          {
            :module => [
              {
                :hour => '05',
                :minute => '24',
                :second => '00'
              }
            ]
          }
        end
      end

      recognizes_as_expected 'time with optional fractional second' do
        let(:rip) { '05:24:00.14159' }
      end

      recognizes_as_expected 'time with optional offset' do
        let(:rip) { '00:24:00-0500' }
      end

      recognizes_as_expected 'time with optional fractional second and optional offset' do
        let(:rip) { '00:24:00.14159-0500' }
        let(:expected_raw) do
          {
            :module => [
              {
                :hour => '00',
                :minute => '24',
                :second => '00',
                :sub_second => '14159',
                :offset => {
                  :sign => '-',
                  :hour => '05',
                  :minute => '00'
                }
              }
            ]
          }
        end
      end

      recognizes_as_expected 'datetime' do
        let(:rip) { '2012-02-12T05:24:00' }
        let(:expected_raw) do
          {
            :module => [
              {
                :date => {
                  :year => '2012',
                  :month => '02',
                  :day => '12'
                },
                :time => {
                  :hour => '05',
                  :minute => '24',
                  :second => '00'
                }
              }
            ]
          }
        end
      end
    end

    context 'molecular literals' do
      recognizes_as_expected 'key-value pairs' do
        let(:rip) { '5: \'five\'' }
        let(:expected_raw) do
          {
            :module => [
              {
                :atom => [
                  { :integer => '5' },
                  {
                    :key_value_pair => {
                      :location => ':',
                      :value => {
                        :location => '\'',
                        :string => rip_string_raw('five')
                      }
                    }
                  }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'ranges' do
        let(:rip) { '1..3' }
        let(:expected_raw) do
          {
            :module => [
              {
                :atom => [
                  { :integer => '1' },
                  {
                    :range => {
                      :end => { :integer => '3' },
                      :location => '..',
                      :exclusivity => nil
                    }
                  }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'exclusive ranges' do
        let(:rip) { '1...age' }
        let(:expected_raw) do
          {
            :module => [
              {
                :atom => [
                  { :integer => '1' },
                  {
                    :range => {
                      :end => { :reference => 'age' },
                      :location => '..',
                      :exclusivity => '.'
                    }
                  }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'empty map' do
        let(:rip) { '{}' }
        let(:expected_raw) do
          {
            :module => [
              {
                :location => '{',
                :map => []
              }
            ]
          }
        end
      end

      recognizes_as_expected 'map with content' do
        let(:rip) do
          <<-RIP
            {
              :age: 31,
              :name: :Thomas
            }
          RIP
        end
        let(:expected_raw) do
          {
            :module => [
              {
                :location => '{',
                :map => [
                  {
                    :atom => [
                      {
                        :location => ':',
                        :string => rip_string_raw('age')
                      },
                      {
                        :key_value_pair => {
                          :location => ':',
                          :value => { :integer => '31' }
                        }
                      }
                    ]
                  },
                  {
                    :atom => [
                      {
                        :location => ':',
                        :string => rip_string_raw('name')
                      },
                      {
                        :key_value_pair => {
                          :location => ':',
                          :value => {
                            :location => ':',
                            :string => rip_string_raw('Thomas')
                          }
                        }
                      }
                    ]
                  }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'empty list' do
        let(:rip) { '[]' }
        let(:expected_raw) do
          {
            :module => [
              {
                :location => '[',
                :list => []
              }
            ]
          }
        end
      end

      recognizes_as_expected 'list with content' do
        let(:rip) do
          <<-RIP
            [
              31,
              :Thomas
            ]
          RIP
        end
        let(:expected_raw) do
          {
            :module => [
              {
                :location => '[',
                :list => [
                  { :integer => '31' },
                  {
                    :location => ':',
                    :string => rip_string_raw('Thomas')
                  }
                ]
              }
            ]
          }
        end
      end
    end
  end
end
