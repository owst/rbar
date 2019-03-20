# rbar

`rbar` is a simple AST-based Ruby refactoring tool.

## Installation

    $ gem install rbar

## Usage

  To inline a variable declared in the "rectangle" whose top-left corner is at
  line l1, and column c1 and whose bottom-right corner is at line l2 column c2:

    rbar inline --file FILENAME --start-pos l1:c1 --end-pos l2:c2

  e.g. for a file foo.rb containing:

    class Foo
      def foo(bar)
        baz = bar + 1
        puts "baz is #{baz}"
      end
    end

  we can inline `baz` with:

    rbar inline --file foo.rb --start-pos 3:5 --end-pos 3:7

  which will emit

    class Foo
      def foo(bar)
        puts "baz is #{bar + 1}"
      end
    end

  on STDOUT.

  N.B. the variable source range must intersect with the input rectangle
  range. If multiple variables are identified by this intersection, the first
  is chosen to be inlined.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/owst/rbar.
