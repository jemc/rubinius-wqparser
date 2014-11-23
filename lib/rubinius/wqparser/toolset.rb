
require 'parser/current'

require "rubinius/toolset"

Rubinius::ToolSets.create :w_q_parser do
  module ::CodeTools; end
  
  require "rubinius/melbourne"
  require "rubinius/ast"
  require_relative "toolset/fake_melbourne"
  require_relative "toolset/processor"
  require "rubinius/compiler"
end

class Rubinius::ToolSets::WQParser::Compiler::Parser
  prepend Module.new {
    def initialize *args
      super
      @processor = Rubinius::ToolSets::WQParser::FakeMelbourne
    end
  }
end
