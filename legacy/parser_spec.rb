require 'hashie'
require 'spec_helper'

describe Rip::Parser do
  describe '.root' do
    specify { expect(Rip::Parser.root).to eq(Pathname.new(__dir__).parent.parent.parent.expand_path) }
  end

  recognizes_as_expected 'several statements together' do
    let(:rip) do
      strip_heredoc(<<-RIP)
        if (true) {
          lambda = -> {
            # comment
            42
          }
          lambda()
        } else {
          1 + 2
        }
      RIP
    end
  end

  describe '#reference' do
    it 'recognizes valid references, including predefined references' do
      [
        'name',
        'Person',
        '==',
        'save!',
        'valid?',
        'long_ref-name',
        '*-+&$~%',
        'one_9',
        'É¹ÇÊ‡É¹oÔ€uÉlâˆ€â„¢',
        'nilly',
        'nil',
        'true',
        'false',
        'Kernel',
        'returner'
      ].each do |reference|
        expect(reference).to parse_as(Hashie::Mash.new(:module => [ { :reference => reference } ]))
      end
    end

    it 'skips invalid references' do
      [
        'one.two',
        '999',
        '6teen',
        'rip rocks',
        'key:value'
      ].each do |non_reference|
        expect(non_reference).to_not parse_as({ :reference => non_reference })
      end
    end
  end

  describe '#property_name' do
    it 'recognizes special-case property names' do
      [
        '/',
        '<=>',
        '<',
        '<<',
        '<=',
        '>',
        '>>',
        '>=',
        '[]'
      ].each do |property_name|
        rip = "@.#{property_name}"
        expected = {
          :module => [
            {
              :object => { :reference => '@' },
              :location => '.',
              :property_name => property_name
            }
          ]
        }
        expect(rip).to parse_as(Hashie::Mash.new(expected))
      end
    end
  end

  describe '#expression' do
    context 'block' do
      recognizes_as_expected 'empty block' do
        let(:rip) { 'try {}' }
      end

      recognizes_as_expected 'block with argument' do
        let(:rip) { 'if (:name) {} else {}' }
      end

      recognizes_as_expected 'block with multiple arguments' do
        let(:rip) { 'type (one, two) {}' }
      end

      recognizes_as_expected 'type with no super_types' do
        let(:rip) do
          <<-RIP
            type {
              # comment
            }
          RIP
        end
        let(:expected) do
          {
            :module => [
              {
                :type => 'type',
                :arguments => [],
                :location_body => '{',
                :body => []
              }
            ]
          }
        end
      end

      recognizes_as_expected 'overload with no parameters' do
        let(:rip) { '-> {}' }
        let(:expected) do
          {
            :module => [
              {
                :dash_rocket => '->',
                :parameters => [],
                :location_body => '{',
                :body => []
              }
            ]
          }
        end
      end

      recognizes_as_expected 'lambda with no parameters' do
        let(:rip) { '=> { -> {} }' }
        let(:expected) do
          {
            :module => [
              {
                :fat_rocket => '=>',
                :location_body => '{',
                :overload_blocks => [
                  {
                    :dash_rocket => '->',
                    :parameters => [],
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
      end

      recognizes_as_expected 'overload with multiple required parameters with type restrictions' do
        let(:rip) { '-> (one, two<CustomType>) {}' }
      end

      recognizes_as_expected 'overload with multiple optional parameters' do
        let(:rip) { '-> (one = 1, two = 2) {}' }
      end

      recognizes_as_expected 'overload with multiple optional parameters with type restrictions' do
        let(:rip) { '-> (one<System.Integer> = 1, two = 2) {}' }
        let(:expected) do
          {
            :module => [
              {
                :dash_rocket => '->',
                :parameters => [
                  {
                    :parameter => 'one',
                    :type_argument => {
                      :object => { :reference => 'System' },
                      :location => '.',
                      :property_name => 'Integer'
                    },
                    :default_expression => { :integer => '1', :sign => '+' }
                  },
                  {
                    :parameter => 'two',
                    :default_expression => { :integer => '2', :sign => '+' }
                  }
                ],
                :location_body => '{',
                :body => []
              }
            ]
          }
        end
      end

      recognizes_as_expected 'overload with required parameter and optional parameter' do
        let(:rip) { '-> (platform, name = :rip) {}' }
      end

      recognizes_as_expected 'overload with multiple required parameter and multiple optional parameter' do
        let(:rip) { '-> (abc, xyz, one = 1, two = 2) {}' }
      end

      recognizes_as_expected 'blocks with block arguments' do
        let(:rip) { 'type (type () {}) {}' }
      end

      recognizes_as_expected 'switch' do
        let(:rip) { 'switch (foo) { case (true) { 42 } else { 0 } }' }
        let(:expected) do
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
                      { :sign => '+', :integer => '42' }
                    ]
                  }
                ],
                :else_block => {
                  :else => 'else',
                  :location_body => '{',
                  :body => [
                    { :sign => '+', :integer => '0' }
                  ]
                }
              }
            ]
          }
        end
      end

      recognizes_as_expected 'switch without argument' do
        let(:rip) { 'switch { case (true) { 42 } else { 0 } }' }
        let(:expected) do
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
                      { :sign => '+', :integer => '42' }
                    ]
                  }
                ],
                :else_block => {
                  :else => 'else',
                  :location_body => '{',
                  :body => [
                    { :sign => '+', :integer => '0' }
                  ]
                }
              }
            ]
          }
        end
      end

      recognizes_as_expected 'try-catch' do
        let(:rip) { 'try {} catch (Exception: e) {}' }
        let(:expected) do
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
                      :key => { :reference => 'Exception' },
                      :location => ':',
                      :value => { :reference => 'e' }
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
        let(:expected) do
          {
            :module => [
              {
                :try_block => {
                  :try => 'try',
                  :location_body => '{',
                  :body => []
                },
                :catch_blocks => [],
                :finally_block => {
                  :finally => 'finally',
                  :location_body => '{',
                  :body => []
                }
              }
            ]
          }
        end
      end

      recognizes_as_expected 'try-catch-finally' do
        let(:rip) { 'try {} catch (Exception: e) {} finally {}' }
        let(:expected) do
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
                      :key => { :reference => 'Exception' },
                      :location => ':',
                      :value => { :reference => 'e' }
                    },
                    :location_body => '{',
                    :body => []
                  }
                ],
                :finally_block => {
                  :finally => 'finally',
                  :location_body => '{',
                  :body => []
                }
              }
            ]
          }
        end
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
      end

      recognizes_as_expected 'references inside block body' do
        let(:rip) { '-> (x) { name }' }
      end

      recognizes_as_expected 'assignments inside block body' do
        let(:rip) { '-> (foo) { x = :y }' }
      end

      recognizes_as_expected 'invocations inside block body' do
        let(:rip) { '-> (run!) { run!() }' }
      end

      recognizes_as_expected 'operator invocations inside block body' do
        let(:rip) { '-> (steam) { steam will :rise }' }
      end

      recognizes_as_expected 'literals inside block body' do
        let(:rip) { '-> (n) { `3 }' }
      end

      recognizes_as_expected 'blocks inside block body' do
        let(:rip) { '-> (foo) { if (false) { 42 } else { -42 } }' }
      end
    end

    recognizes_as_expected 'keyword' do
      let(:rip) { 'return;' }
    end

    recognizes_as_expected 'keyword followed by phrase' do
      let(:rip) { 'exit 0' }
    end

    recognizes_as_expected 'keyword followed by parenthesis around phrase' do
      let(:rip) { 'throw (e)' }
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
        let(:expected) do
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
        let(:expected) do
          {
            :module => [
              {
                :callable => {
                  :object => {
                    :callable => {
                      :object => { :sign => '+', :integer => '1' },
                      :location => '+',
                      :property_name => '+'
                    },
                    :location => '+',
                    :arguments => [
                      { :sign => '+', :integer => '2' }
                    ]
                  },
                  :location => '-',
                  :property_name => '-'
                },
                :location => '-',
                :arguments => [
                  { :sign => '+', :integer => '3' }
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
      end

      recognizes_as_expected 'lambda reference invocation' do
        let(:rip) { 'full_name()' }
      end

      recognizes_as_expected 'lambda reference invocation arguments' do
        let(:rip) { 'full_name(:Thomas, :Ingram)' }
      end

      recognizes_as_expected 'index invocation' do
        let(:rip) { 'list[0]' }
      end

      recognizes_as_expected 'operator invocation' do
        let(:rip) { '2 + 2' }
      end

      recognizes_as_expected 'reference assignment' do
        let(:rip) { 'favorite_language = :rip' }
        let(:expected) do
          {
            :module => [
              {
                :lhs => { :reference => 'favorite_language' },
                :location => '=',
                :rhs => { :location => ':', :string => rip_string('rip') }
              }
            ]
          }
        end
      end

      recognizes_as_expected 'property assignment' do
        let(:rip) { 'favorite.language = :rip.lang' }
        let(:expected) do
          {
            :module => [
              {
                :lhs => {
                  :object => { :reference => 'favorite' },
                  :location => '.',
                  :property_name => 'language'
                },
                :location => '=',
                :rhs => {
                  :object => { :location => ':', :string => rip_string('rip') },
                  :location => '.',
                  :property_name => 'lang'
                }
              }
            ]
          }
        end
      end
    end

    context 'nested parenthesis' do
      recognizes_as_expected 'anything surrounded by parenthesis' do
        let(:rip) { '(0)' }
      end

      recognizes_as_expected 'anything surrounded by parenthesis with crazy nesting' do
        let(:rip) { '((((((l((1 + (((2 - 3)))))))))))' }
      end
    end

    context 'property chaining' do
      recognizes_as_expected 'chaining with properies and invocations' do
        let(:rip) { '0.one().two.three()' }
      end

      recognizes_as_expected 'chaining off opererators' do
        let(:rip) { '(1 - 2).zero?()' }
      end

      recognizes_as_expected 'chaining several opererators' do
        let(:rip) { '1 + 2 + 3 + 4' }
      end
    end

    context 'atomic literals' do
      describe 'numbers' do
        recognizes_as_expected 'integer' do
          let(:rip) { '42' }
          let(:expected) do
            {
              :module => [
                { :sign => '+', :integer => '42' }
              ]
            }
          end
        end

        recognizes_as_expected 'decimal' do
          let(:rip) { '4.2' }
          let(:expected) do
            {
              :module => [
                { :sign => '+', :decimal => '4.2' }
              ]
            }
          end
        end

        recognizes_as_expected 'negative number' do
          let(:rip) { '-3' }
          let(:expected) do
            {
              :module => [
                { :sign => '-', :integer => '3' }
              ]
            }
          end
        end

        recognizes_as_expected 'large number' do
          let(:rip) { '123_456_789' }
          let(:expected) do
            {
              :module => [
                { :sign => '+', :integer => '123_456_789' }
              ]
            }
          end
        end
      end

      recognizes_as_expected 'regular character' do
        let(:rip) { '`9' }
        let(:expected) do
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
        let(:expected) do
          {
            :module => [
              {
                :location => '`',
                :character => "\n"
              }
            ]
          }
        end
      end

      recognizes_as_expected 'symbol string' do
        let(:rip) { ':0' }
      end

      recognizes_as_expected 'symbol string with escape' do
        let(:rip) { ':on\e' }
        let(:expected) do
          {
            :module => [
              {
                :location => ':',
                :string => [
                  { :location => 'o', :character => 'o' },
                  { :location => 'n', :character => 'n' },
                  { :location => '\\', :character => '\\' },
                  { :location => 'e', :character => 'e' }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'single-quoted string (empty)' do
        let(:rip) { "''" }
        let(:expected) do
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
      end

      recognizes_as_expected 'double-quoted string (empty)' do
        let(:rip) { '""' }
        let(:expected) do
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
        let(:expected) do
          {
            :module => [
              {
                :location => '"',
                :string => [
                  { :location => 'a', :character => 'a' },
                  { :location => "\n", :character => "\n" },
                  { :location => 'b', :character => 'b' }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'double-quoted string with interpolation' do
        let(:rip) { '"ab#{cd}ef"' }
        let(:expected) do
          {
            :module => [
              {
                :callable => {
                  :object => {
                    :callable => {
                      :object => {
                        :location => '"',
                        :string => rip_string('ab')
                      },
                      :location => '+',
                      :property_name => '+'
                    },
                    :location => '+',
                    :arguments => [
                      {
                        :start => '#{',
                        :interpolation => [
                          { :reference => 'cd' }
                        ],
                        :end => '}'
                      }
                    ]
                  },
                  :location => '+',
                  :property_name => '+'
                },
                :location => '+',
                :arguments => [
                  {
                    :location => '"',
                    :string => rip_string('ef')
                  }
                ]
              }
            ]
          }
        end
      end

      recognizes_as_expected 'empty heredoc' do
        let(:rip) { "<<HERE_DOC\nHERE_DOC" }
        let(:expected) do
          {
            :module => [
              {
                :location => '<<',
                :string => rip_string('')
              }
            ]
          }
        end
      end

      recognizes_as_expected 'heredoc with just blank lines' do
        let(:rip) { "<<HERE_DOC\r\n\r\n\r\nHERE_DOC\r\n" }
        let(:expected) do
          {
            :module => [
              {
                :location => '<<',
                :string => rip_string("\r\n\r\n")
              }
            ]
          }
        end
      end

      recognizes_as_expected 'heredoc with just indented lines' do
        let(:rip) { "\t<<HERE_DOC\n\t\n\t\n\tHERE_DOC\n" }
        let(:expected) do
          {
            :module => [
              {
                :location => '<<',
                :string => rip_string("\t\n\t\n")
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
        let(:expected) do
          {
            :module => [
              {
                :location => '<<',
                :string => rip_string("i'm a HERE_DOC\nHERE_DOC are multi-line strings\n")
              }
            ]
          }
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
      end
    end

    context 'date and time literals' do
      recognizes_as_expected 'date' do
        let(:rip) { '2012-02-12' }
        let(:expected) do
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
        let(:expected) do
          {
            :module => [
              {
                :hour => '05',
                :minute => '24',
                :second => '00',
                :sub_second => '0',
                :offset => {
                  :sign => '+',
                  :hour => '00',
                  :minute => '00'
                }
              }
            ]
          }
        end
      end

      recognizes_as_expected 'time with optional fractional second' do
        let(:rip) { '05:24:00.14159' }
        let(:expected) do
          {
            :module => [
              {
                :hour => '05',
                :minute => '24',
                :second => '00',
                :sub_second => '14159',
                :offset => {
                  :sign => '+',
                  :hour => '00',
                  :minute => '00'
                }
              }
            ]
          }
        end
      end

      recognizes_as_expected 'time with optional offset' do
        let(:rip) { '00:24:00-0500' }
        let(:expected) do
          {
            :module => [
              {
                :hour => '00',
                :minute => '24',
                :second => '00',
                :sub_second => '0',
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

      recognizes_as_expected 'time with optional fractional second and optional offset' do
        let(:rip) { '00:24:00.14159-0500' }
        let(:expected) do
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
        let(:expected) do
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
                  :second => '00',
                  :sub_second => '0',
                  :offset => {
                    :sign => '+',
                    :hour => '00',
                    :minute => '00'
                  }
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
      end

      recognizes_as_expected 'ranges' do
        let(:rip) { '1..3' }
      end

      recognizes_as_expected 'exclusive ranges' do
        let(:rip) { '1...age' }
      end

      recognizes_as_expected 'empty map' do
        let(:rip) { '{}' }
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
      end

      recognizes_as_expected 'empty list' do
        let(:rip) { '[]' }
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
      end
    end
  end
end
