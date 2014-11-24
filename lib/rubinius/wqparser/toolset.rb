
require 'parser/current'

require "rubinius/toolset"

Rubinius::ToolSets.create :w_q_parser do
  require "rubinius/compiler"
  require "rubinius/ast"
  require "rubinius/melbourne"
  
  require_relative "toolset/fake_melbourne"
  require_relative "toolset/processor"
end

class Rubinius::ToolSets::WQParser::Compiler::Parser
  prepend Module.new {
    def initialize *args
      super
      @processor = Rubinius::ToolSets::WQParser::FakeMelbourne
    end
  }
end
