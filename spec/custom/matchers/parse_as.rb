# The ParseAsMatcher wraps the logic for checking that a string of Ruby code
# is converted to the expected s-expression. It is combined with the #parse_as
# spec helper and enables specs of the form:
#
#   "a = 1".should parse_as([:lasgn, :a, [:lit, 1]])
#
class ParseAsMatcher
  def initialize(expected)
    @expected = expected
  end

  def source_to_ast(source)
    compiler = Rubinius::ToolSets::WQParser::Compiler.new :string, :ast
    compiler.parser.root Rubinius::ToolSets::WQParser::AST::Script
    compiler.parser.input source, '(snippet)', 1
    compiler.run
    compiler.parser.instance_variable_get(:@output).body
  end

  def matches?(actual)
    @actual = source_to_ast(actual).to_sexp.to_a
    @actual == @expected
  end

  def failure_message
    ["Expected:\n#{@actual.pretty_inspect}\n",
     "to equal:\n#{@expected.pretty_inspect}"]
  end
end

class Object
  def parse_as(sexp)
    ParseAsMatcher.new sexp
  end
end
