module Rbar
  module Inline
    def self.rewrite(input_buffer, range:)
      rewrite_collector = InlineVariableRewriteCollector.new(range)
      rewrite_collector.process(Parser::CurrentRuby.new.parse(input_buffer))

      rewriter = Parser::Source::Rewriter.new(input_buffer)
      rewrite_collector.schedule_rewrites(rewriter)
      rewriter.process
    end

    MatchedVariable = Struct.new(:source_line_range, :name, :value)

    class InlineVariableRewriteCollector < Parser::AST::Processor
      def initialize(range)
        @range = range
        @replacement_collector = nil
      end

      def schedule_rewrites(source_rewriter)
        @replacement_collector.schedule_rewrites(source_rewriter) if @replacement_collector
      end

      def on_begin(begin_node)
        begin_node.children.each do |child|
          if @replacement_collector
            if @replacement_collector.modifying_assignment?(child)
              @replacement_collector.reset
              break
            else
              @replacement_collector.process(child)

              break if @replacement_collector.variable_redefinition?(child)
            end
          elsif target_declaration?(child)
            matched_variable = MatchedVariable.new(
              line_containing(child.loc.expression),
              child.children[0],
              child.children[1].loc.expression.source
            )

            @replacement_collector = ScopeRespectingReplacementCollector.new(matched_variable)
          else
            super
          end
        end
      end

      private

      def target_declaration?(child)
        child.type == :lvasgn && child.loc.expression.overlaps?(@range)
      end

      def line_containing(range)
        source_buffer = range.source_buffer
        source = source_buffer.source

        start_pos = range.begin_pos
        start_pos -= 1 while source[start_pos] =~ /[ \t]/
        end_pos = range.end_pos
        end_pos += 1 while source[end_pos] =~ /[ \t\n]/

        Parser::Source::Range.new(source_buffer, start_pos, end_pos)
      end
    end

    class ScopeRespectingReplacementCollector < Parser::AST::Processor
      def initialize(matched_variable)
        @matched_variable = matched_variable
        @name = matched_variable.name
        @replacements = []
      end

      def schedule_rewrites(source_rewriter)
        unless @replacements.empty?
          @replacements.each do |replacement_range|
            source_rewriter.replace(replacement_range, @matched_variable.value)
          end

          source_rewriter.remove(@matched_variable.source_line_range)
        end
      end

      def on_lvar(node)
        @replacements << node.loc.expression if same_name?(node)
      end

      def on_begin(node)
        node.children.each do |child|
          break if variable_redefinition?(child)

          process(child)
        end
      end

      def on_def(node)
        super unless binds_same_arg?(node)
      end

      def on_block(node)
        super unless binds_same_arg?(node)
      end

      def reset
        @replacements = []
      end

      def modifying_assignment?(node)
        node.type == :op_asgn && same_name?(node)
      end

      def variable_redefinition?(node)
        node.type == :lvasgn && same_name?(node)
      end

      private

      def binds_same_arg?(node)
        _, args, _ = *node

        args.children.any? do |arg|
          if arg.type == :mlhs
            arg.children.any? { |nested_arg| same_name?(nested_arg) }
          else
            same_name?(arg)
          end
        end
      end

      def same_name?(node)
        node.loc.name.source == @name.to_s
      end
    end
  end
end
