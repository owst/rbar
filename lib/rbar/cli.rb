require 'thor'

module Rbar
  class Cli < Thor
    package_name 'rbar'

    class << self
      private

      def add_common_options
        desc = 'Position given as LINE:COL'
        option(:start_pos, required: true, desc: desc)
        option(:end_pos, required: true, desc: desc)
        option(:file, required: true)
      end
    end

    desc 'inline', 'Inlines the local variable located by the start/end pos'
    add_common_options
    def inline
      print Rbar::Inline.rewrite(buffer, range: range)
    end

    desc 'rename', 'Renames the local variable located by the start/end pos to the given new_name'
    add_common_options
    option(:new_name, required: true)
    def rename
      print Rbar::Rename.rewrite(buffer, options[:new_name], range: range)
    end

    no_commands do
      private

      # A rectangle range with start_pos as the top-left and end_pos as the bottom-right.
      def range
        start_line, start_col = to_line_col(options[:start_pos])
        end_line, end_col = to_line_col(options[:end_pos])

        start_line = buffer.line_range(start_line)
        start_range = Parser::Source::Range.new(
          buffer,
          start_line.begin_pos + start_col,
          start_line.end_pos
        )

        end_range = buffer.line_range(end_line).begin
        end_range.resize(end_col)

        start_range.join(end_range)
      end

      def buffer
        @buffer ||= Parser::Source::Buffer.new(options[:file]).tap { |buffer| buffer.read }
      end

      def to_line_col(range_spec)
        range_spec.split(':').map(&:to_i)
      end
    end
  end
end
