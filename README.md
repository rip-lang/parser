## Rip Parser

This project parses and validates [Rip](http://www.rip-lang.org/) source code.


### Usage

```ruby
require 'rip-parser'

package_root = Pathname.new(__dir__)
syntax_tree = Rip::Parser.load_file(package_root + 'source' + 'foo.rip')
```
