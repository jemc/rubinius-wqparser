#!/usr/bin/env rake
# require "bundler/gem_tasks"
require "redcard"

# if RedCard.check :rubinius
#   namespace :spec do
#     desc "Load the parser into the Spec ToolSet"
#     task :toolset do
#       Rubinius::ToolSet.start
#       require_relative "sandbox.rb"
#       Rubinius::ToolSet.finish :spec
#     end
#   end

#   dependencies = %w[spec:toolset]
# else
  dependencies = []
# end

desc "Run the specs"
task :spec => dependencies do
  # exec "mspec spec -G fails"
  sh "mspec -I #{File.dirname __FILE__} -r spec/spec_helper spec -G fails"
end

task :sandbox do
  require_relative 'lib/rubinius/wqparser'
  
  def parse source, &block
    # require 'pry'
    # binding.pry
    ast = Rubinius::ToolSets::WQParser::FakeMelbourne \
      .parse_string source, '(snippet)', 1
    
    # compiler = Rubinius::ToolSets::WQParser::Compiler.new :string, :ast
    # compiler.parser.root Rubinius::ToolSets::WQParser::AST::Script
    # compiler.parser.input source, '(snippet)', 1
    # compiler.parser.run
    # ast = compiler.parser.instance_variable_get(:@output).body
    
    # require 'pp'
    puts ast.ascii_graph
    puts
    
    actual = ast.to_sexp
    puts "      : #{source}"
    puts "expect: #{block.call.inspect}"
    puts "actual: #{actual.inspect}"
    puts block.call == actual ? "PASS" : "FAIL"
  end
end

task :default => :spec
# task :default => :sandbox
