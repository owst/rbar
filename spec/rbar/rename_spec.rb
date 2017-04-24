require 'spec_helper'

module Rbar
  describe Rename do
    def expect_rewrite(input, line, expected)
      buffer = buffer(input)
      expect(Rename.rewrite(buffer, 'y', range: buffer.line_range(line))).to eq expected
    end

    def buffer(input)
      Parser::Source::Buffer.new('(string)').tap do |buffer|
        buffer.source = input
      end
    end

    it "doesn't avoid name collisons with existing variables/methods" do
      src = <<~'SRC'
        def y
          1
        end

        def some_method
          x = 1
          y = 2
          p x
        end
      SRC

      expected = <<~'EXPECTED'
        def y
          1
        end

        def some_method
          y = 1
          y = 2
          p y
        end
      EXPECTED

      expect_rewrite(src, 6, expected)
    end

    it 'renames a used-once variable' do
      src = <<~'SRC'
        def some_method
          x = 1
          p x
        end
      SRC

      expected = <<~'EXPECTED'
        def some_method
          y = 1
          p y
        end
      EXPECTED

      expect_rewrite(src, 2, expected)
    end

    it 'renames a used-once variable inside a class' do
      src = <<~'SRC'
        class Foo
          def some_method
            x = 1
            p x
          end
        end
      SRC

      expected = <<~'EXPECTED'
        class Foo
          def some_method
            y = 1
            p y
          end
        end
      EXPECTED

      expect_rewrite(src, 3, expected)
    end

    it 'renames a conditionally modified variable' do
      src = <<~'SRC'
        def some_method
          x = 1
          x += x if condition
          p x
        end
      SRC

      expected = <<~'EXPECTED'
        def some_method
          y = 1
          y += y if condition
          p y
        end
      EXPECTED

      expect_rewrite(src, 2, expected)
    end

    it 'renames a modified variable' do
      src = <<~'SRC'
        def some_method
          x = 1
          x += 1
          p x
        end
      SRC

      expected = <<~'EXPECTED'
        def some_method
          y = 1
          y += 1
          p y
        end
      EXPECTED

      expect_rewrite(src, 2, expected)
    end

    it 'renames the first variable if multiple are identified by the range' do
      src = <<~'SRC'
        class Foo
          def some_method
            x = 1
            y = 2
            puts x, y
          end
        end
      SRC

      expected = <<~'EXPECTED'
        class Foo
          def some_method
            z = 1
            y = 2
            puts z, y
          end
        end
      EXPECTED

      buffer = buffer(src)
      range = buffer.line_range(3).join(buffer.line_range(4))
      expect(Rename.rewrite(buffer, 'z', range: range)).to eq expected
    end

    it 'renames a used-once variable inside nested modules' do
      src = <<~'SRC'
        module Foo
          module Bar
            def self.some_method
              x = 1
              p x
            end
          end
        end
      SRC

      expected = <<~'EXPECTED'
        module Foo
          module Bar
            def self.some_method
              y = 1
              p y
            end
          end
        end
      EXPECTED

      expect_rewrite(src, 4, expected)
    end

    it 'renames a variable conditionally passed to a function' do
      src = <<~'SRC'
        def some_method
          x = 1
          x = f(x) if condition
          p x
        end
      SRC

      expected = <<~'EXPECTED'
        def some_method
          y = 1
          y = f(y) if condition
          p y
        end
      EXPECTED

      expect_rewrite(src, 2, expected)
    end

    it 'renames a variable passed to a function' do
      src = <<~'SRC'
        def some_method
          x = 1
          x = f(x)
          p x
        end
      SRC

      expected = <<~'EXPECTED'
        def some_method
          y = 1
          y = f(y)
          p y
        end
      EXPECTED

      expect_rewrite(src, 2, expected)
    end

    it 'correctly renames non-shadowed variables' do
      src = <<~'SRC'
        def some_method
          x = 1
          p x
          ->(x) { p x }
          x = 2
          p x
        end
      SRC

      expected = <<~'EXPECTED'
        def some_method
          y = 1
          p y
          ->(x) { p x }
          y = 2
          p y
        end
      EXPECTED

      expect_rewrite(src, 2, expected)
    end

    context "if the range doesn't overlap a variable" do
      def expect_no_rename(start_pos, end_pos)
        buffer = buffer(src)
        range = Parser::Source::Range.new(buffer, start_pos, end_pos)
        expect(Rename.rewrite(buffer, 'y', range: range)).to eq src
      end

      let(:src) {
        <<~'SRC'
          def some_method
            x = 1
            p x
          end
        SRC
      }

      it "doesn't rename for every range before the variable definition" do
        (0..src.index('x')).each do |end_pos|
          expect_no_rename(0, end_pos)
        end
      end

      it "doesn't rename for every range after the variable's value" do
        (src.index('1') + 1..src.length).each do |start_pos|
          expect_no_rename(start_pos, src.length)
        end
      end
    end

    it "doesn't rename block params" do
      src = <<~'SRC'
        def some_method
          x = 1
          foo { |x| p x }
          ->(x) { p x }
          foo { p x }
          -> { p x }
        end
      SRC

      expected = <<~'EXPECTED'
        def some_method
          y = 1
          foo { |x| p x }
          ->(x) { p x }
          foo { p y }
          -> { p y }
        end
      EXPECTED

      expect_rewrite(src, 2, expected)
    end

    it "doesn't rename a multi-bound variable" do
      src = <<~'SRC'
        def some_method
          x, y = [1, 2]
          p x
        end
      SRC

      expect_rewrite(src, 2, src)
    end
  end
end

