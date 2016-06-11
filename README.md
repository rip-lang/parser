```
         _            _          _
        /\ \         /\ \       /\ \
       /  \ \        \ \ \     /  \ \
      / /\ \ \       /\ \_\   / /\ \ \
     / / /\ \_\     / /\/_/  / / /\ \_\
    / / /_/ / /    / / /    / / /_/ / /
   / / /__\/ /    / / /    / / /__\/ /
  / / /_____/    / / /    / / /_____/
 / / /\ \ \  ___/ / /__  / / /
/ / /  \ \ \/\__\/_/___\/ / /
\/_/    \_\/\/_________/\/_/
```

## What is Rip

Rip is a general purpose programming language. It is a functional language with an object-oriented syntax. All objects are immutable, so it might help to think of objects as collections of partially-applied functions.

## Development Status

In progress. Use at your own risk. **You should assume nothing works yet!**

## License

Rip is released under the MIT license. Please see `LICENSE.md` for more details.

## Quick Start (Contributers):

0. Install Ruby 2. I use [rbenv](https://github.com/sstephenson/rbenv) and [ruby-build](https://github.com/sstephenson/ruby-build), but use whatever floats your boat.
0. `$ git clone git://github.com/rip-lang/rip-parser.git`
0. `$ cd rip-parser`
0. `$ bundle install`
0. `$ bundle exec rspec`

## Getting Help

If you find a bug or have any other issue, please open a [ticket](https://github.com/rip-lang/rip-parser/issues). You should include as many details as reasonably possible, such as operating system, Ruby version (`ruby --version`), the Rip source code that broke et cetera.

## Contributing

Patches are most welcome! Please make changes in a feature branch that merges into master cleanly. Existing tests should not break, and new code needs new tests.
