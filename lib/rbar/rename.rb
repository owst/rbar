module Rbar
  module Rename
    def self.rewrite(input_buffer, new_name, range:)
      rewrite_collector = RenameVariableRewriteCollector.new(range, new_name)
      rewrite_collector.process(Parser::CurrentRuby.new.parse(input_buffer))

      rewriter = Parser::Source::Rewriter.new(input_buffer)
      rewrite_collector.schedule_rewrites(rewriter)
      rewriter.process
    end

    class RenameVariableRewriteCollector < Parser::AST::Processor
      def initialize(range, new_name)
        @range = range
        @new_name = new_name
        @replacement_collector = nil
      end

      def schedule_rewrites(source_rewriter)
        @replacement_collector.schedule_rewrites(source_rewriter) if @replacement_collector
      end

      def on_begin(begin_node)
        begin_node.children.each do |child|
          if @replacement_collector
            @replacement_collector.process(child)
          elsif target_declaration?(child)
            @replacement_collector = ScopeRespectingRenameCollector.new(child, @new_name)
          else
            super
          end
        end
      end

      private

      def target_declaration?(child)
        child.type == :lvasgn && child.loc.expression.overlaps?(@range)
      end
    end

    class ScopeRespectingRenameCollector < Parser::AST::Processor
      def initialize(matched_variable, new_name)
        @name = matched_variable.children[0]
        @new_name = new_name
        @replacements = [matched_variable.loc.name]
      end

      def schedule_rewrites(source_rewriter)
        @replacements.each do |replacement_range|
          source_rewriter.replace(replacement_range, @new_name)
        end
      end

      def on_lvasgn(node)
        return unless same_name?(node)

        @replacements << node.loc.name
        super
      end

      def on_lvar(node)
        @replacements << node.loc.name if same_name?(node)
      end

      def on_def(node)
        super unless binds_same_arg?(node)
      end

      def on_block(node)
        super unless binds_same_arg?(node)
      end

      private

      def binds_same_arg?(node)
        _, args, _ = *node

        args.children.any? { |arg| same_name?(arg) }
      end

      def same_name?(node)
        node.loc.name.source == @name.to_s
      end
    end
  end
end
