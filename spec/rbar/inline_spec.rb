require 'spec_helper'

module Rbar
  describe Inline do
    def expect_rewrite(input, line, expected)
      buffer = buffer(input)
      expect(Inline.rewrite(buffer, range: buffer.line_range(line))).to eq expected
    end

    def buffer(input)
      Parser::Source::Buffer.new('(string)').tap do |buffer|
        buffer.source = input
      end
    end

    it 'inlines a used-once variable' do
      src = <<~'SRC'
        def some_method
          x = 1
          p x
        end
      SRC

      expected = <<~'EXPECTED'
        def some_method
          p 1
        end
      EXPECTED

      expect_rewrite(src, 2, expected)
    end

    it 'inlines a used-once variable inside a class' do
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
            p 1
          end
        end
      EXPECTED

      expect_rewrite(src, 3, expected)
    end

    it 'inlines a used-once variable inside nested modules' do
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
              p 1
            end
          end
        end
      EXPECTED

      expect_rewrite(src, 4, expected)
    end

    it 'inlines a used-once variable and removes resulting blank lines' do
      src = <<~'SRC'
        def some_method
          x = 1

          p x
        end
      SRC

      expected = <<~'EXPECTED'
        def some_method
          p 1
        end
      EXPECTED

      expect_rewrite(src, 2, expected)
    end

    it 'inlines a variable passed to a function' do
      src = <<~'SRC'
        def some_method
          x = 1
          x = f(x)
          p x
        end
      SRC

      expected = <<~'EXPECTED'
        def some_method
          x = f(1)
          p x
        end
      EXPECTED

      expect_rewrite(src, 2, expected)
    end

    it 'inlines a variable with a multi-line definition' do
      src = <<~'SRC'
        def some_method
          x = [
            1,
            2,
          ]
          p x
        end
      SRC

      expected = <<~'EXPECTED'
        def some_method
          p [
            1,
            2,
          ]
        end
      EXPECTED

      expect_rewrite(src, 2, expected)
    end

    it 'correctly inlines non-shadowed variables' do
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
          p 1
          ->(x) { p x }
          x = 2
          p x
        end
      EXPECTED

      expect_rewrite(src, 2, expected)
    end

    it 'inlines variables' do
      src = <<~'SRC'
        def some_method
          x = 1
          p x
          y = x
          x = 1
          p x
        end
      SRC

      expected = <<~'EXPECTED'
        def some_method
          p 1
          y = 1
          x = 1
          p x
        end
      EXPECTED

      expect_rewrite(src, 2, expected)
    end

    it "doesn't inline an unused variable" do
      src = <<~'SRC'
        def some_method
          x = 1
          p y
        end
      SRC

      expect_rewrite(src, 2, src)
    end

    context "if the range doesn't overlap a variable" do
      def expect_no_inline(start_pos, end_pos)
        buffer = buffer(src)
        range = Parser::Source::Range.new(buffer, start_pos, end_pos)
        expect(Inline.rewrite(buffer, range: range)).to eq src
      end

      let(:src) {
        <<~'SRC'
          def some_method
            x = 1
            p x
          end
        SRC
      }

      it "doesn't inline for every range before the variable definition" do
        (0..src.index('x')).each do |end_pos|
          expect_no_inline(0, end_pos)
        end
      end

      it "doesn't inline for every range after the variable's value" do
        (src.index('1') + 1..src.length).each do |start_pos|
          expect_no_inline(start_pos, src.length)
        end
      end
    end

    it "doesn't inline block params" do
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
          foo { |x| p x }
          ->(x) { p x }
          foo { p 1 }
          -> { p 1 }
        end
      EXPECTED

      expect_rewrite(src, 2, expected)
    end

    it "doesn't inline a multi-bound variable" do
      src = <<~'SRC'
        def some_method
          x, y = [1, 2]
          p x
        end
      SRC

      expect_rewrite(src, 2, src)
    end

    it "doesn't inline a modified variable" do
      src = <<~'SRC'
        def some_method
          x = 1
          x += 1
          p x
        end
      SRC

      expect_rewrite(src, 2, src)
    end
  end
end
